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

      # Look back 24h — sufficient to find the current 5-hour block
      lookback_start=$(date -u -d "@$((now_epoch - 86400))" +%Y-%m-%dT%H:%M:%S)

      # Collect assistant entries from the last 24h, including dedup key.
      # Dedup key = message_id:request_id (matches upstream Claude-Code-Usage-Monitor).
      all_entries=$({
        while IFS= read -r f; do
          jq -c --arg ls "$lookback_start" \
            'select(.type == "assistant" and
                    ((.timestamp // "") | split(".")[0] | rtrimstr("Z")) >= $ls)
             | {
                 u:    .message.usage,
                 ts:   (.timestamp // ""),
                 hash: ((.message_id // .message.id // "") + ":"
                        + (.requestId // .request_id // ""))
               }' \
            "$f" 2>/dev/null
        done < <(find "$projects_dir" -name '*.jsonl' 2>/dev/null)
      } | jq -sc 'sort_by(.ts)')

      # Group into fixed 5-hour blocks (block_end = block_start + 5h; next entry
      # after block_end starts a new block). Deduplicate by hash. Count only
      # input_tokens + output_tokens — cache tokens do not count toward the quota
      # (matches upstream behaviour).
      current_block=$(jq --argjson quota "$quota" '
        if length == 0 then
          {input: 0, output: 0, block_start: "", quota: $quota}
        else
          (reduce .[] as $e (
            {bs: null, be: null, seen: {}, input: 0, output: 0};
            ($e.ts | split(".")[0] | rtrimstr("Z")
                   | strptime("%Y-%m-%dT%H:%M:%S") | mktime) as $ep |
            (if .bs == null or $ep > .be then
              {bs: $e.ts, be: ($ep + 18000), seen: {}, input: 0, output: 0}
            else . end) |
            if (.seen[$e.hash] // false) then .
            else
              . + {seen: (.seen + {($e.hash): true}),
                   input:  (.input  + ($e.u.input_tokens  // 0)),
                   output: (.output + ($e.u.output_tokens // 0))}
            end
          )) |
          {block_start: .bs, input: .input, output: .output, quota: $quota}
        end
      ' <<< "$all_entries")

      block_start_ts=$(jq -r '.block_start' <<< "$current_block")
      if [ -n "$block_start_ts" ]; then
        block_start_epoch=$(date -d "$block_start_ts" +%s)
        reset_epoch=$((block_start_epoch + window_secs))
        secs_left=$((reset_epoch - now_epoch))
        if [ "$secs_left" -le 0 ]; then
          reset_str="now"
        else
          h=$((secs_left / 3600))
          m=$(((secs_left % 3600) / 60))
          if [ "$h" -gt 0 ]; then
            reset_str="$h h $m m"
          elif [ "$m" -gt 0 ]; then
            reset_str="$m m"
          else
            reset_str="<1 m"
          fi
        fi
        reset_at=$(date -d "@$reset_epoch" +%H:%M)
      else
        reset_str="--"
        reset_at="--"
      fi

      text=$(jq -r --arg reset "$reset_str" '
        (.input + .output) as $total |
        ($total * 100 / .quota) as $pct |
        "🤖 \($pct | round)% ↻ \($reset)"
      ' <<< "$current_block")

      tooltip=$(jq -r --arg reset_at "$reset_at" '
        (.input + .output) as $total |
        ($total * 100 / .quota | round) as $pct |
        "Claude Code — 5h block (\($pct)% of quota)\n" +
        "Tokens used: \($total | tostring) / \(.quota | tostring)\n" +
        "Input:       \(.input  | tostring) tokens\n" +
        "Output:      \(.output | tostring) tokens\n" +
        "Resets at:   \($reset_at)"
      ' <<< "$current_block")

      class=$(jq -r '
        (.input + .output) as $total |
        ($total * 100 / .quota) as $pct |
        if $pct >= 80 then "critical"
        elif $pct >= 50 then "warning"
        else "normal"
        end
      ' <<< "$current_block")

      jq -cn \
        --arg text    "$text" \
        --arg tooltip "$tooltip" \
        --arg class   "$class" \
        '{"text": $text, "tooltip": $tooltip, "class": $class}'
    '';
  }
