{pkgs}:
pkgs.writeShellScriptBin "qs-nvidia" ''
  set -euo pipefail

  # Query GPU 0: name, driver_version, utilization.gpu, memory.used, memory.total,
  # temperature.gpu, power.draw, fan.speed, clocks.gr, clocks.mem
  IFS=',' read -r gpu_name driver_ver gpu_util mem_used mem_total gpu_temp power_draw fan_speed clock_gr clock_mem < <(
    nvidia-smi \
      --id=0 \
      --query-gpu=name,driver_version,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,fan.speed,clocks.gr,clocks.mem \
      --format=csv,noheader,nounits \
      2>/dev/null
  )

  trim() { echo "$1" | sed 's/^ *//; s/ *$//'; }
  gpu_name=$(trim "$gpu_name")
  driver_ver=$(trim "$driver_ver")
  gpu_util=$(trim "$gpu_util")
  mem_used=$(trim "$mem_used")
  mem_total=$(trim "$mem_total")
  gpu_temp=$(trim "$gpu_temp")
  power_draw=$(trim "$power_draw")
  fan_speed=$(trim "$fan_speed")
  clock_gr=$(trim "$clock_gr")
  clock_mem=$(trim "$clock_mem")

  if [ -z "''${gpu_util:-}" ]; then
    jq -cn '{"text":"GPU N/A","tooltip":"nvidia-smi unavailable","class":"normal"}'
    exit 0
  fi

  mem_pct=$(( mem_used * 100 / mem_total ))
  power_int=$(awk -v p="$power_draw" 'BEGIN { printf "%.0f", p }')

  text="GPU ''${gpu_util}% · ''${gpu_temp}°C"

  tooltip=$(printf "%s\nDriver %s\n\nUtilization: %s%%\nVRAM:        %s / %s MiB  (%s%%)\nTemperature: %s°C\nPower:       %s W\nFan:         %s%%\nGPU clock:   %s MHz\nMem clock:   %s MHz" \
    "$gpu_name" "$driver_ver" \
    "$gpu_util" "$mem_used" "$mem_total" "$mem_pct" \
    "$gpu_temp" "$power_int" "$fan_speed" "$clock_gr" "$clock_mem")

  if [ "$gpu_util" -ge 80 ] || [ "$gpu_temp" -ge 85 ]; then
    class="critical"
  elif [ "$gpu_util" -ge 50 ] || [ "$gpu_temp" -ge 70 ]; then
    class="warning"
  else
    class="normal"
  fi

  jq -cn \
    --arg text    "$text" \
    --arg tooltip "$tooltip" \
    --arg class   "$class" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
''
