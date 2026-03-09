{
  lib,
  writeShellApplication,
  voxtype,
  libnotify,
}:
writeShellApplication {
  name = "voxtype-meeting-pause-toggle";
  runtimeInputs = [voxtype libnotify];
  text = ''
    status=$(voxtype meeting status 2>&1)
    if echo "$status" | grep -qi "no meeting"; then
      notify-send "VoxType Meeting" "No meeting in progress"
      exit 0
    fi
    if echo "$status" | grep -qi "paused"; then
      voxtype meeting resume
      notify-send "VoxType Meeting" "Meeting resumed"
    else
      voxtype meeting pause
      notify-send "VoxType Meeting" "Meeting paused"
    fi
  '';
  meta = {
    description = "Toggle VoxType meeting pause/resume";
    license = lib.licenses.mit;
    mainProgram = "voxtype-meeting-pause-toggle";
  };
}
