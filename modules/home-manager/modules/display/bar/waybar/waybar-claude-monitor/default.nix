{pkgs, ...}:
pkgs.writeShellApplication {
  name = "waybar-claude-monitor";
  runtimeInputs = [pkgs.toybox pkgs.findutils pkgs.jq];
  text = ''
    today=$(date +%Y-%m-%d)
    projects_dir="$HOME/.config/claude/projects"

    usage=$({
      while IFS= read -r f; do
        jq -c --arg today "$today" \
          'select(.type == "assistant" and (.timestamp | startswith($today))) | .message.usage' \
          "$f" 2>/dev/null
      done < <(find "$projects_dir" -name '*.jsonl' 2>/dev/null)
    } | jq -sc '{
        input:       (map(.input_tokens                      // 0) | add // 0),
        cache_write: (map(.cache_creation_input_tokens       // 0) | add // 0),
        cache_read:  (map(.cache_read_input_tokens           // 0) | add // 0),
        output:      (map(.output_tokens                     // 0) | add // 0)
      } | . + {
        cost: (
          (.input       * 3.0   / 1000000) +
          (.cache_write * 3.75  / 1000000) +
          (.cache_read  * 0.30  / 1000000) +
          (.output      * 15.0  / 1000000)
        )
      }')

    text=$(jq -r '"🤖 $" + (.cost * 100 | round / 100 | tostring)' <<< "$usage")

    tooltip=$(jq -r '
      "Claude Code — today\n" +
      "Input:       \(.input       | tostring) tokens\n" +
      "Cache write: \(.cache_write | tostring) tokens\n" +
      "Cache read:  \(.cache_read  | tostring) tokens\n" +
      "Output:      \(.output      | tostring) tokens\n" +
      "Cost:        $\(.cost * 100 | round / 100 | tostring)"
    ' <<< "$usage")

    class=$(jq -r '
      .cost | if . >= 50 then "critical" elif . >= 20 then "warning" else "normal" end
    ' <<< "$usage")

    jq -cn \
      --arg text    "$text" \
      --arg tooltip "$tooltip" \
      --arg class   "$class" \
      '{"text": $text, "tooltip": $tooltip, "class": $class}'
  '';
}
