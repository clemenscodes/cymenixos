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

        if [[ -n "''${1:-}" ]]; then
          meeting_id="$1"
          metadata=$(find "$meetings_dir" -name "metadata.json" -print0 | xargs -0 grep -l "\"id\": \"$meeting_id\"" 2>/dev/null | head -1)
        else
          # Fallback: latest meeting with actual content, sorted by ended_at
          metadata=$(
            find "$meetings_dir" -name "metadata.json" | while IFS= read -r f; do
              count=$(jq -r '.chunk_count // 0' "$f")
              ended=$(jq -r '.ended_at // ""' "$f")
              if [[ "$count" -gt 0 ]] && [[ -n "$ended" ]]; then
                echo "$ended $f"
              fi
            done | sort -r | head -1 | cut -d' ' -f2-
          )
          meeting_id=$(jq -r '.id' "$metadata")
        fi

        if [[ -z "$meeting_id" ]] || [[ "$meeting_id" == "null" ]]; then
          notify-send "VoxType Meeting" "No meeting to export"
          exit 0
        fi

        meeting_dir=$(jq -r '.storage_path' "$metadata")
        out_file="$meeting_dir/export.md"
        chunk_count=$(jq -r '.chunk_count' "$metadata")

        # Wait for recording to stop
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

        # Wait for all chunks to be transcribed
        transcript_file="$meeting_dir/transcript.json"
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

        if ! transcript=$(voxtype meeting export "$meeting_id" --format markdown --timestamps --speakers --metadata 2>&1) || echo "$transcript" | grep -qi "no meeting"; then
          notify-send "VoxType Meeting" "No meeting to export"
          exit 0
        fi

        output="$transcript"
        if summary=$(voxtype meeting summarize "$meeting_id" --format markdown 2>&1) && ! echo "$summary" | grep -qi "error"; then
          output="$output

    ---

    # Summary

    $summary"
        fi

        printf '%s\n' "$output" | prettier --prose-wrap always --print-width 80 --parser markdown > "$out_file"

        # Create a human-readable symlink named by recording time for easy navigation
        ended_at=$(jq -r '.ended_at // ""' "$metadata")
        if [[ -n "$ended_at" ]] && [[ "$ended_at" != "null" ]]; then
          readable_name=$(date -d "$ended_at" "+%Y-%m-%d_%H-%M" 2>/dev/null || true)
          if [[ -n "$readable_name" ]]; then
            link_path="$meetings_dir/$readable_name"
            # Append short id suffix on collision (two meetings in the same minute)
            if [[ -e "$link_path" ]] && [[ "$(readlink -f "$link_path")" != "$meeting_dir" ]]; then
              link_path="''${link_path}_''${meeting_id:0:8}"
            fi
            ln -sfn "$meeting_dir" "$link_path"
          fi
        fi

        notify-send "VoxType Meeting" "Transcript saved to $out_file"
  '';
  meta = {
    description = "Export latest VoxType meeting transcript with AI summary to disk";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-export";
  };
}
