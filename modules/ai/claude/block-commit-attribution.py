"""PreToolUse hook: nothing that leaves this machine carries a Claude attribution.

The Bash command is parsed with shfmt into a real syntax tree, so only actual
invocations of git, gh, curl, ... count, not the same words inside paths,
heredoc bodies or the source of an awk or python script. Messages and bodies
read from a file are not blocked outright, the file is read and checked.
"""

import json
import os
import re
import subprocess
import sys

ATTRIBUTION = re.compile(
    r"co-authored-by|generated with \[?claude|noreply@anthropic\.com|claude\.com/claude-code",
    re.IGNORECASE,
)
OUTWARD = {
    "gh", "glab", "tea", "hub", "az", "curl", "wget", "xh", "http", "https",
    "ssh", "scp", "sftp", "rsync", "nc", "ncat", "socat",
}
GIT_OUTWARD = {
    "commit", "tag", "notes", "merge", "push", "am", "rebase", "revert",
    "cherry-pick", "send-email", "request-pull",
}
WRAPPERS = {
    "sudo", "doas", "env", "command", "exec", "nohup", "time", "nice",
    "ionice", "stdbuf", "xargs", "builtin", "timeout",
}
SHELLS = {"bash", "sh", "zsh", "dash"}
DYNAMIC = "\0"


def deny(reason):
    print("DENIED: " + reason, file=sys.stderr)
    print("Nothing that leaves this machine ever carries a Claude attribution", file=sys.stderr)
    print("(Co-Authored-By, 'Generated with Claude Code', noreply@anthropic.com).", file=sys.stderr)
    sys.exit(2)


def parse(script):
    result = subprocess.run(
        ["shfmt", "--to-json", "--language-dialect", "bash"],
        input=script, capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    return json.loads(result.stdout)


class Analyzer:
    def __init__(self, cwd):
        self.cwd = cwd
        self.vars = {}
        self.outward = False
        # (path or DYNAMIC, what) pairs whose content goes out
        self.sources = []
        # directories whose unpushed commits get published
        self.pushes = []
        self.pipe_source = None
        self.stmt_redirs = []

    # words

    def word(self, word):
        text = ""
        for part in (word or {}).get("Parts", []):
            text += self.part(part, quoted=False)
        return text

    def part(self, part, quoted):
        kind = part.get("Type")
        if kind == "Lit":
            value = part.get("Value", "")
            return value if quoted else re.sub(r"\\(.)", r"\1", value)
        if kind == "SglQuoted":
            return part.get("Value", "")
        if kind == "DblQuoted":
            return "".join(self.part(p, quoted=True) for p in part.get("Parts", []))
        if kind == "ParamExp" and not any(part.get(k) for k in ("Exp", "Slice", "Repl", "Index", "Length", "Excl", "Names")):
            name = (part.get("Param") or {}).get("Value", "")
            if name in self.vars:
                return self.vars[name]
            if name in os.environ:
                return os.environ[name]
        return DYNAMIC

    def path(self, text, cwd):
        if DYNAMIC in text:
            return DYNAMIC
        return os.path.normpath(os.path.join(cwd, os.path.expanduser(text)))

    # tree walk

    def walk(self, node, cwd_box):
        if isinstance(node, list):
            for item in node:
                self.walk(item, cwd_box)
            return
        if not isinstance(node, dict):
            return
        if node.get("Type") == "BinaryCmd" and node.get("Op") in ("|", "|&"):
            self.walk(node.get("X"), cwd_box)
            self.pipe_source = node.get("X")
            self.walk(node.get("Y"), cwd_box)
            self.pipe_source = None
            return
        if isinstance(node.get("Cmd"), dict):
            self.stmt_redirs = node.get("Redirs") or [] if node["Cmd"].get("Type") == "CallExpr" else []
        if node.get("Type") == "CallExpr":
            self.call(node, cwd_box)
        for key, value in node.items():
            if key in ("Pos", "End") or not isinstance(value, (dict, list)):
                continue
            if node.get("Type") == "CallExpr" and key in ("Args", "Assigns"):
                # command substitutions inside the words still count
                self.walk_substs(value, cwd_box)
                continue
            self.walk(value, cwd_box)

    def walk_substs(self, node, cwd_box):
        if isinstance(node, list):
            for item in node:
                self.walk_substs(item, cwd_box)
        elif isinstance(node, dict):
            if node.get("Type") in ("CmdSubst", "ProcSubst"):
                self.walk(node.get("Stmts"), dict(cwd_box))
                return
            for key, value in node.items():
                if isinstance(value, (dict, list)):
                    self.walk_substs(value, cwd_box)

    def call(self, node, cwd_box):
        argv = [self.word(w) for w in node.get("Args") or []]
        if not argv:
            for assign in node.get("Assigns") or []:
                name = (assign.get("Name") or {}).get("Value")
                if name:
                    self.vars[name] = self.word(assign.get("Value"))
            return
        self.command(argv, cwd_box, self.stmt_redirs)

    def command(self, argv, cwd_box, redirs):
        argv = unwrap(argv)
        if not argv:
            return
        name = os.path.basename(argv[0])
        args = argv[1:]
        if name == "cd":
            target = next((a for a in args if not a.startswith("-")), "~")
            cwd_box["cwd"] = self.path(target, cwd_box["cwd"]) if DYNAMIC not in target else cwd_box["cwd"]
            return
        if name in SHELLS or name == "eval":
            script = None
            if name == "eval":
                script = " ".join(args)
            elif "-c" in args and args.index("-c") + 1 < len(args):
                script = args[args.index("-c") + 1]
            if script and DYNAMIC not in script:
                tree = parse(script)
                if tree is not None:
                    self.walk(tree, cwd_box)
            return
        stdin = self.stdin_sources(redirs, cwd_box["cwd"])
        if name == "git":
            self.git(args, cwd_box["cwd"], stdin)
        elif name in OUTWARD:
            self.outward = True
            if name == "gh":
                self.gh(args, cwd_box["cwd"], stdin)
            elif name in ("curl", "wget", "xh", "http", "https"):
                self.http(name, args, cwd_box["cwd"], stdin)

    def stdin_sources(self, redirs, cwd):
        found = []
        for redir in redirs:
            if redir.get("Op") == "<":
                found.append(self.path(self.word(redir.get("Word")), cwd))
        source = self.pipe_source
        if source is not None:
            # cat file | cmd: the files the left side reads
            sub = Analyzer(cwd)
            sub.vars = self.vars
            files = []

            def collect(node):
                if isinstance(node, list):
                    for item in node:
                        collect(item)
                elif isinstance(node, dict):
                    if node.get("Type") == "CallExpr":
                        for w in (node.get("Args") or [])[1:]:
                            text = sub.word(w)
                            if not text.startswith("-"):
                                files.append(sub.path(text, cwd))
                    for value in node.values():
                        if isinstance(value, (dict, list)):
                            collect(value)
            collect(source)
            found.extend(f for f in files if f == DYNAMIC or os.path.isfile(f))
        return found

    def add(self, value, cwd, stdin, what):
        if value == "-":
            self.sources.extend((s, what + " from stdin") for s in stdin)
        else:
            self.sources.append((self.path(value, cwd), what))

    def git(self, args, cwd, stdin):
        i = 0
        while i < len(args) and args[i].startswith("-"):
            if args[i] == "-C" and i + 1 < len(args):
                cwd = self.path(args[i + 1], cwd)
                i += 2
                continue
            i += 2 if args[i] in ("-c", "--git-dir", "--work-tree", "--namespace") else 1
        if i >= len(args) or args[i] not in GIT_OUTWARD:
            return
        sub, rest = args[i], args[i + 1:]
        self.outward = True
        if sub == "push":
            self.pushes.append(cwd)
        if sub in ("commit", "tag", "notes", "merge"):
            for value in option_values(rest, short="Ft", long=("--file", "--template"), takes="mcCFtSu"):
                self.add(value, cwd, stdin, "git message")

    def gh(self, args, cwd, stdin):
        if args[:1] == ["api"]:
            for value in option_values(args[1:], short="", long=("--input",)):
                self.add(value, cwd, stdin, "gh api payload")
            for value in option_values(args[1:], short="F", long=("--field",), takes="FfHXpqtj"):
                if "=@" in value:
                    self.add(value.split("=@", 1)[1], cwd, stdin, "gh api field")
            return
        for value in option_values(args, short="F", long=("--body-file", "--notes-file"), takes="FbtmalpRBHdrnwj"):
            self.add(value, cwd, stdin, "gh body")

    def http(self, name, args, cwd, stdin):
        if name == "wget":
            for value in option_values(args, short="", long=("--post-file", "--body-file")):
                self.add(value, cwd, stdin, "request body")
            return
        if name == "curl":
            for value in option_values(args, short="TK", long=("--upload-file", "--config")):
                self.add(value, cwd, stdin, "request body")
            for value in option_values(args, short="F", long=("--form", "--form-string")):
                match = re.search(r"=[@<]([^;]+)", value)
                if match:
                    self.add(match.group(1), cwd, stdin, "form field")
            for value in option_values(args, short="d", long=("--data", "--data-binary", "--data-ascii", "--data-urlencode", "--json")):
                if value.startswith("@"):
                    self.add(value[1:], cwd, stdin, "request body")
                elif re.match(r"^[^=@]*@", value) and "--data-urlencode" in args:
                    self.add(value.split("@", 1)[1], cwd, stdin, "request body")
            return
        # httpie and xh: @file bodies, field=@file and field:=@file
        for arg in args:
            if arg.startswith("@"):
                self.add(arg[1:], cwd, stdin, "request body")
            else:
                match = re.match(r"^[^=:@-][^=:@]*(?:=|:=)@(.+)$", arg)
                if match:
                    self.add(match.group(1), cwd, stdin, "request field")
        if stdin:
            self.sources.extend((s, "request body from stdin") for s in stdin)


def unwrap(argv):
    while argv:
        name = os.path.basename(argv[0])
        if name in WRAPPERS:
            argv = argv[1:]
            while argv and (argv[0].startswith("-") or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[0])):
                takes = argv[0] in ("-u", "-g", "-n", "-s", "-C", "-I", "-L", "-P", "-k", "-c")
                argv = argv[2:] if takes else argv[1:]
            if name == "timeout" and argv:
                argv = argv[1:]
            continue
        if name == "nix" and len(argv) > 1 and argv[1] == "run":
            rest = argv[2:]
            target = next((a for a in rest if not a.startswith("-")), "")
            tail = rest[rest.index("--") + 1:] if "--" in rest else []
            return [target.split("#", 1)[-1]] + tail
        if name == "nix" and len(argv) > 1 and argv[1] in ("shell", "develop"):
            for flag in ("-c", "--command"):
                if flag in argv:
                    argv = argv[argv.index(flag) + 1:]
                    break
            else:
                return []
            continue
        return argv
    return argv


def option_values(args, short, long, takes=""):
    """Values of the given short and long options, stopping at --."""
    values = []
    i = 0
    while i < len(args):
        arg = args[i]
        if arg == "--":
            break
        if arg.startswith("--"):
            key, eq, value = arg.partition("=")
            if key in long:
                if eq:
                    values.append(value)
                elif i + 1 < len(args):
                    values.append(args[i + 1])
                    i += 1
        elif arg.startswith("-") and len(arg) > 1:
            for pos, char in enumerate(arg[1:], start=1):
                if char in short:
                    value = arg[pos + 1:]
                    if value:
                        values.append(value)
                    elif i + 1 < len(args):
                        values.append(args[i + 1])
                        i += 1
                    break
                if char in takes:
                    if pos + 1 == len(arg):
                        i += 1
                    break
        i += 1
    return values


def carries(path):
    try:
        with open(path, "rb") as handle:
            data = handle.read(16 * 1024 * 1024)
    except OSError:
        return False
    return bool(ATTRIBUTION.search(data.decode("utf-8", "replace")))


def main():
    data = json.load(sys.stdin)
    tool = data.get("tool_name") or ""
    if tool.startswith("mcp__"):
        if ATTRIBUTION.search(json.dumps(data.get("tool_input"))):
            deny("the input of %s contains a Claude attribution." % tool)
        return
    if tool != "Bash":
        return
    cmd = (data.get("tool_input") or {}).get("command") or ""
    if not cmd:
        return

    tree = parse(cmd)
    if tree is None:
        # bash rejects it as well, so it never runs; only the plain text is left
        if ATTRIBUTION.search(cmd):
            deny("the command contains a Claude attribution. Remove it and run the command again.")
        return

    analyzer = Analyzer(data.get("cwd") or os.getcwd())
    analyzer.walk(tree, {"cwd": analyzer.cwd})
    if not analyzer.outward:
        return

    if ATTRIBUTION.search(cmd):
        deny("the command contains a Claude attribution. Remove it and run the command again.")

    for path, what in analyzer.sources:
        if path == DYNAMIC:
            deny("%s from a path this hook cannot resolve. Use a literal path or pass it inline." % what)
        if carries(path):
            deny("%s %s contains a Claude attribution." % (what, path))

    for directory in analyzer.pushes:
        if directory == DYNAMIC:
            continue
        log = subprocess.run(
            ["git", "-C", directory, "log", "--format=%B", "--branches", "--not", "--remotes"],
            capture_output=True, text=True,
        )
        if log.returncode == 0 and ATTRIBUTION.search(log.stdout):
            deny("an unpushed commit in %s carries a Claude attribution. Reword it before pushing." % directory)


if __name__ == "__main__":
    main()
