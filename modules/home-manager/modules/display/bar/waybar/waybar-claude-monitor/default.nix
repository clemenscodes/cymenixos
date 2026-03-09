{
  pkgs,
  quota,
}: let
  quotaStr = toString quota;
in
  pkgs.writeShellApplication {
    name = "waybar-claude-monitor";
    runtimeInputs = [pkgs.coreutils pkgs.findutils pkgs.jq pkgs.gawk];
    text = ''
      projects_dir="$HOME/.config/claude/projects"
      quota=${quotaStr}
      now_epoch=$(date +%s)
      window_secs=$((5 * 3600))

      # Pass 1: find current block start by running the sequential block algorithm
      # over ALL historical timestamps (cheap: only extracts one field per line).
      # Each block ends at block_start + 5h; the next entry after that starts a
      # new block. Processing all history is the only way to get correct boundaries.
      #
      # jq emits "epoch<space>timestamp" per entry; sort orders them chronologically;
      # awk applies the cascade and prints the last (current) block's start timestamp.
      block_start_epoch=$(
        find "$projects_dir" -name '*.jsonl' 2>/dev/null \
        | while IFS= read -r f; do
            jq -r 'select(.type == "assistant" and .timestamp != null)
                   | ( .timestamp | split(".")[0] | rtrimstr("Z")
                       | strptime("%Y-%m-%dT%H:%M:%S") | mktime | tostring )' \
              "$f" 2>/dev/null
          done \
        | sort -n \
        | awk -v ws=18000 -v now="$now_epoch" '
            {
              ep = $1 + 0
              if (block_start_ep == "" || ep >= block_end) {
                block_start_ep = int(ep / 3600) * 3600
                block_end      = block_start_ep + ws
              }
            }
            END {
              if (block_start_ep != "" && block_end > now)
                print block_start_ep
            }
          '
      )

      if [ -z "$block_start_epoch" ]; then
        # No active block — show 0% so the widget stays visible
        jq -cn '{"text":"Claude 0%","tooltip":"No active Claude Code block.","class":"normal"}'
        exit 0
      fi

      # block_start_epoch is already floored to the hour (matches upstream algorithm)
      reset_epoch=$((block_start_epoch + window_secs))
      secs_left=$((reset_epoch - now_epoch))
      reset_at=$(date -d "@$reset_epoch" +%H:%M)

      block_start_utc=$(date -u -d "@$block_start_epoch" +%Y-%m-%dT%H:%M:%S)
      block_end_utc=$(date -u -d "@$reset_epoch" +%Y-%m-%dT%H:%M:%S)

      # Pass 2: collect entries in the current block, deduplicate by
      # message_id:request_id, count only input_tokens + output_tokens
      # (cache tokens do not count toward Claude Code's quota limit).
      block_entries=$({
        while IFS= read -r f; do
          jq -c --arg bs "$block_start_utc" --arg be "$block_end_utc" \
            'select(.type == "assistant" and .timestamp != null) |
             (.timestamp | split(".")[0] | rtrimstr("Z")) as $t |
             select($t >= $bs and $t < $be) |
             { u:    .message.usage,
               hash: ((.message_id // .message.id // "") + ":"
                      + (.requestId // .request_id // "")) }' \
            "$f" 2>/dev/null
        done < <(find "$projects_dir" -name '*.jsonl' 2>/dev/null)
      } | jq -sc .)

      totals=$(jq --argjson quota "$quota" '
        reduce .[] as $e (
          {seen: {}, input: 0, output: 0};
          if (.seen[$e.hash] // false) then .
          else . + {seen: (.seen + {($e.hash): true}),
                    input:  (.input  + ($e.u.input_tokens  // 0)),
                    output: (.output + ($e.u.output_tokens // 0))}
          end
        ) | {input, output, quota: $quota}
      ' <<< "$block_entries")

      if [ "$secs_left" -le 0 ]; then
        reset_str="now"
      else
        h=$((secs_left / 3600))
        m=$(((secs_left % 3600) / 60))
        if [ "$h" -gt 0 ]; then
          reset_str="''${h}h ''${m}m"
        elif [ "$m" -gt 0 ]; then
          reset_str="''${m}m"
        else
          reset_str="<1m"
        fi
      fi

      text=$(jq -r --arg reset "$reset_str" '
        (.input + .output) as $total |
        ($total * 100 / .quota) as $pct |
        "Claude \($pct | round)% · \($reset)"
      ' <<< "$totals")

      tooltip=$(jq -r --arg reset_at "$reset_at" '
        (.input + .output) as $total |
        ($total * 100 / .quota | round) as $pct |
        "Claude Code — 5h block (\($pct)% of quota)\n" +
        "Tokens used: \($total | tostring) / \(.quota | tostring)\n" +
        "Input:       \(.input  | tostring) tokens\n" +
        "Output:      \(.output | tostring) tokens\n" +
        "Resets at:   \($reset_at)"
      ' <<< "$totals")

      class=$(jq -r '
        (.input + .output) as $total |
        ($total * 100 / .quota) as $pct |
        if $pct >= 80 then "critical"
        elif $pct >= 50 then "warning"
        else "normal"
        end
      ' <<< "$totals")

      jq -cn \
        --arg text    "$text" \
        --arg tooltip "$tooltip" \
        --arg class   "$class" \
        '{"text": $text, "tooltip": $tooltip, "class": $class}'
    '';
  }
