{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
  wl-clipboard,
}:
writeShellApplication {
  name = "voxtype-meeting-export";
  runtimeInputs = [voxtype libnotify wl-clipboard];
  text = ''
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

    echo "$output" | fold -s -w 80 | wl-copy
    notify-send "VoxType Meeting" "Transcript and summary copied to clipboard"
  '';
  meta = {
    description = "Export latest VoxType meeting transcript with AI summary to clipboard";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-export";
  };
}
