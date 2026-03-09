{
  pkgs,
  quota,
}: let
  quotaStr = toString quota;
in
  pkgs.writeShellApplication {
    name = "waybar-claude-monitor";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq];
    text = ''
      projects_dir="$HOME/.config/claude/projects"
      quota=${quotaStr}
      now_epoch=$(date +%s)
      window_secs=$((5 * 3600))
      window_start_epoch=$((now_epoch - window_secs))
      window_start=$(date -u -d "@$window_start_epoch" +%Y-%m-%dT%H:%M:%S)

      window_raw=$({
        while IFS= read -r f; do
          jq -c --arg ws "$window_start" \
            'select(.type == "assistant" and ((.timestamp // "") | ltrimstr("Z") | split(".")[0]) >= $ws)
             | {u: .message.usage, ts: (.timestamp // "")}' \
            "$f" 2>/dev/null
        done < <(find "$projects_dir" -name '*.jsonl' 2>/dev/null)
      } | jq -sc .)

      usage=$(jq --argjson quota "$quota" '{
        input:       ([.[].u.input_tokens                      // 0] | add // 0),
        cache_write: ([.[].u.cache_creation_input_tokens       // 0] | add // 0),
        cache_read:  ([.[].u.cache_read_input_tokens           // 0] | add // 0),
        output:      ([.[].u.output_tokens                     // 0] | add // 0),
        oldest_ts:   (map(select(.ts != "")) | map(.ts) | min // ""),
        quota:       $quota
      }' <<< "$window_raw")

      oldest_ts=$(jq -r '.oldest_ts' <<< "$usage")
      if [ -n "$oldest_ts" ]; then
        oldest_epoch=$(date -d "$oldest_ts" +%s)
        reset_epoch=$((oldest_epoch + window_secs))
        secs_left=$(( reset_epoch - now_epoch ))
        if [ "$secs_left" -le 0 ]; then
          reset_str="now"
        else
          h=$(( secs_left / 3600 ))
          m=$(( (secs_left % 3600) / 60 ))
          if [ "$h" -gt 0 ]; then
            reset_str="$h h $m m"
          else
            reset_str="$m m"
          fi
        fi
        reset_at=$(date -d "@$reset_epoch" +%H:%M)
      else
        reset_str="--"
        reset_at="--"
      fi

      text=$(jq -r --arg reset "$reset_str" '
        (.input + .cache_write + .cache_read + .output) as $total |
        ($total * 100 / .quota) as $pct |
        "🤖 \($pct | round)% ↻ \($reset)"
      ' <<< "$usage")

      cost=$(jq '
        (.input       * 3.0   / 1000000) +
        (.cache_write * 3.75  / 1000000) +
        (.cache_read  * 0.30  / 1000000) +
        (.output      * 15.0  / 1000000)
      ' <<< "$usage")
      cost_fmt=$(jq -r '. * 100 | round / 100 | tostring' <<< "$cost")

      tooltip=$(jq -r --arg reset_at "$reset_at" --arg cost "$cost_fmt" '
        (.input + .cache_write + .cache_read + .output) as $total |
        ($total * 100 / .quota | round) as $pct |
        "Claude Code — 5h window (\($pct)% of quota)\n" +
        "Input:       \(.input       | tostring) tokens\n" +
        "Cache write: \(.cache_write | tostring) tokens\n" +
        "Cache read:  \(.cache_read  | tostring) tokens\n" +
        "Output:      \(.output      | tostring) tokens\n" +
        "Cost:        $\($cost)\n" +
        "Resets at:   \($reset_at)"
      ' <<< "$usage")

      class=$(jq -r '
        (.input + .cache_write + .cache_read + .output) as $total |
        ($total * 100 / .quota) as $pct |
        if $pct >= 80 then "critical"
        elif $pct >= 50 then "warning"
        else "normal"
        end
      ' <<< "$usage")

      jq -cn \
        --arg text    "$text" \
        --arg tooltip "$tooltip" \
        --arg class   "$class" \
        '{"text": $text, "tooltip": $tooltip, "class": $class}'
    '';
  }
