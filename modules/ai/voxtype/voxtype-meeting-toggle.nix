{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
  voxtype-meeting-export,
}:
writeShellApplication {
  name = "voxtype-meeting-toggle";
  runtimeInputs = [voxtype libnotify voxtype-meeting-export];
  text = ''
    status=$(voxtype meeting status 2>&1)
    if echo "$status" | grep -qi "no meeting"; then
      voxtype meeting start
      notify-send "VoxType Meeting" "Meeting started"
    else
      voxtype meeting stop
      notify-send "VoxType Meeting" "Meeting stopped, transcribing..."
      while ! voxtype meeting status 2>&1 | grep -qi "no meeting"; do
        sleep 1
      done
      voxtype-meeting-export
    fi
  '';
  meta = {
    description = "Toggle VoxType meeting recording (start/stop)";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-toggle";
  };
}
