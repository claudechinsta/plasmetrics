#!/bin/sh
# Claude subscription usage (5-hour session and 7-day weekly windows), read with the OAuth login
# Claude Code left in ~/.claude/.credentials.json. Nothing is stored, refreshed or written back.
# Output: "claude <state>", "plan <name>", then the usage JSON.
# state: ok | none (no login found) | noscope | expired | nocurl | http<code>
# The token is only ever sent to api.anthropic.com, and goes to curl through stdin so it never shows in `ps`.
umask 077
# $1 = seconds an answer is reused (half the refresh interval), default 30
ttl=${1:-30}
# fresh <file> <seconds>: succeeds when the file was written less than that many seconds ago
fresh() { [ -e "$1" ] && [ $(( $(date +%s) - $(date -r "$1" +%s 2>/dev/null || echo 0) )) -lt "$2" ]; }
f=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json
[ -r "$f" ] || { echo "claude none"; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "claude nocurl"; exit 0; }

# Only the claudeAiOauth object (the file can also hold tokens of MCP servers)
o=$(tr -d '\n' <"$f" | sed -n 's/.*"claudeAiOauth" *: *{\([^}]*\)}.*/\1/p')
tok=$(printf '%s' "$o" | sed -n 's/.*"accessToken" *: *"\([^"]*\)".*/\1/p')
exp=$(printf '%s' "$o" | sed -n 's/.*"expiresAt" *: *\([0-9]*\).*/\1/p')
plan=$(printf '%s' "$o" | sed -n 's/.*"subscriptionType" *: *"\([^"]*\)".*/\1/p')
case $tok in ""|*[!A-Za-z0-9._~+/=-]*) echo "claude none"; exit 0;; esac
case $o in *user:profile*) ;; *) echo "claude noscope"; exit 0;; esac
# Claude Code renews the token while it is in use; an expired one is left alone
[ -n "$exp" ] && [ $((exp / 1000)) -le "$(date +%s)" ] && { echo "claude expired"; echo "plan $plan"; exit 0; }

# The endpoint rate limits hard, so share one answer between refreshes and widget instances,
# and stay quiet for 5 minutes after it says "too many requests"
c=${XDG_RUNTIME_DIR:-/tmp}/plasmetrics-claude-$(id -u)
if fresh "$c.wait" 300; then echo "claude http429"; echo "plan $plan"; exit 0; fi
if fresh "$c" "$ttl"; then cat "$c"; exit 0; fi

r=$(printf 'header = "Authorization: Bearer %s"\n' "$tok" | curl -sS -m 15 -K - \
      -H 'anthropic-beta: oauth-2025-04-20' -H 'Accept: application/json' -H 'User-Agent: Plasmetrics' \
      -w '\n%{http_code}' https://api.anthropic.com/api/oauth/usage 2>/dev/null)
code=$(printf '%s\n' "$r" | tail -n1)
case $code in
  200) { echo "claude ok"; echo "plan $plan"; printf '%s\n' "$r" | sed '$d'; } | tee "$c.$$" >/dev/null; [ "$(wc -l <"$c.$$")" -gt 2 ] && mv "$c.$$" "$c" || rm -f "$c.$$"; cat "$c" 2>/dev/null;;
  429) : >"$c.wait"; echo "claude http429"; echo "plan $plan";;
  *) echo "claude http${code:-0}"; echo "plan $plan";;
esac
