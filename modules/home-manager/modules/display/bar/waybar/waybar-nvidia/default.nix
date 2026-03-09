{pkgs}:
  pkgs.writeShellScriptBin "waybar-nvidia" ''
    set -euo pipefail

    # Query GPU 0: utilization.gpu, memory.used, memory.total, temperature.gpu, power.draw
    read -r gpu_util mem_used mem_total gpu_temp power_draw < <(
      nvidia-smi \
        --id=0 \
        --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw \
        --format=csv,noheader,nounits \
        2>/dev/null \
      | tr -d ' '  \
      | tr ',' ' '
    )

    if [ -z "''${gpu_util:-}" ]; then
      jq -cn '{"text":"GPU N/A","tooltip":"nvidia-smi unavailable","class":"normal"}'
      exit 0
    fi

    mem_pct=$(( mem_used * 100 / mem_total ))
    power_int=$(awk -v p="$power_draw" 'BEGIN { printf "%.0f", p }')

    text="GPU ''${gpu_util}% · ''${gpu_temp}°C"

    tooltip=$(printf "NVIDIA GPU\nUtilization: %s%%\nVRAM:        %s MiB / %s MiB (%s%%)\nTemperature: %s°C\nPower:       %s W" \
      "$gpu_util" "$mem_used" "$mem_total" "$mem_pct" "$gpu_temp" "$power_int")

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
