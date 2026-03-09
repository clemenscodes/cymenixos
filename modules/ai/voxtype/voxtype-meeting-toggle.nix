{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
  jq,
  voxtype-meeting-export,
}:
writeShellApplication {
  name = "voxtype-meeting-toggle";
  runtimeInputs = [voxtype libnotify jq voxtype-meeting-export];
  text = ''
    meetings_dir="$HOME/.local/share/voxtype/meetings"
    status=$(voxtype meeting status 2>&1)
    if echo "$status" | grep -qi "no meeting"; then
      voxtype meeting start
      notify-send "VoxType Meeting" "Meeting started"
    else
      active_meta=$(find "$meetings_dir" -name "metadata.json" -print0 | xargs -0 grep -l '"status": "active"' 2>/dev/null | head -1)
      meeting_id=$(jq -r '.id' "$active_meta")
      voxtype meeting stop
      notify-send "VoxType Meeting" "Meeting stopped, transcribing..."
      while ! voxtype meeting status 2>&1 | grep -qi "no meeting"; do
        sleep 1
      done
      voxtype-meeting-export "$meeting_id"
    fi
  '';
  meta = {
    description = "Toggle VoxType meeting recording (start/stop)";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-toggle";
  };
}
