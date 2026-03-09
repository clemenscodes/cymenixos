{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
  prettier,
  jq,
}:
writeShellApplication {
  name = "voxtype-meeting-export";
  runtimeInputs = [voxtype libnotify prettier jq];
  text = ''
    meetings_dir="$HOME/.local/share/voxtype/meetings"
    latest_dir=$(find "$meetings_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -1 | cut -f2-)
    out_file="$latest_dir/export.md"
    metadata="$latest_dir/metadata.json"
    transcript_file="$latest_dir/transcript.json"

    # Wait for recording to stop (status: active -> completed)
    timeout=120
    elapsed=0
    while [[ "$(jq -r '.status' "$metadata" 2>/dev/null)" == "active" ]]; do
      if (( elapsed >= timeout )); then
        notify-send "VoxType Meeting" "Timed out waiting for recording to stop"
        exit 1
      fi
      sleep 2
      (( elapsed += 2 ))
    done

    # Wait for all chunks to be transcribed (total_chunks == chunk_count)
    chunk_count=$(jq -r '.chunk_count' "$metadata")
    elapsed=0
    while true; do
      if [[ -f "$transcript_file" ]]; then
        transcribed=$(jq -r '.total_chunks' "$transcript_file" 2>/dev/null)
        if [[ "$transcribed" == "$chunk_count" ]]; then
          break
        fi
      fi
      if (( elapsed >= timeout )); then
        notify-send "VoxType Meeting" "Timed out waiting for transcription to finish"
        exit 1
      fi
      sleep 2
      (( elapsed += 2 ))
    done

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

    printf '%s\n' "$output" | prettier --prose-wrap always --print-width 80 --parser markdown > "$out_file"
    notify-send "VoxType Meeting" "Transcript saved to $out_file"
  '';
  meta = {
    description = "Export latest VoxType meeting transcript with AI summary to disk";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-export";
  };
}
