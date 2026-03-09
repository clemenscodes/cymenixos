{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
}:
writeShellApplication {
  name = "voxtype-meeting-export";
  runtimeInputs = [voxtype libnotify];
  text = ''
    meetings_dir="$HOME/.local/share/voxtype/meetings"
    latest_dir=$(find "$meetings_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -1 | cut -f2-)
    out_file="$latest_dir/export.md"

    if ! transcript=$(voxtype meeting export latest --format markdown --timestamps --speakers --metadata 2>&1) || echo "$transcript" | grep -qi "no meeting"; then
      notify-send "VoxType Meeting" "No meeting to export"
      exit 0
    fi

    output="$transcript"
    if summary=$(voxtype meeting summarize latest --format markdown 2>&1) && ! echo "$summary" | grep -qi "error"; then
      output="$output

---

# Summary

$summary"
    fi

    echo "$output" | fold -s -w 80 > "$out_file"
    notify-send "VoxType Meeting" "Transcript saved to $out_file"
  '';
  meta = {
    description = "Export latest VoxType meeting transcript with AI summary to disk";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-export";
  };
}
