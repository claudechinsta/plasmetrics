#!/bin/sh
# Codex plan usage (5-hour session and weekly windows), read with the login the Codex CLI left in
# ~/.codex/auth.json. Nothing is stored, refreshed or written back.
# Output: "codex <state>", then the usage JSON.
# state: ok | none (no login found) | expired | nocurl | http<code>
# The token is only ever sent to chatgpt.com, and goes to curl through stdin so it never shows in `ps`.
umask 077
# $1 = seconds an answer is reused (half the refresh interval), default 30
ttl=${1:-30}
# fresh <file> <seconds>: succeeds when the file was written less than that many seconds ago
fresh() { [ -e "$1" ] && [ $(( $(date +%s) - $(date -r "$1" +%s 2>/dev/null || echo 0) )) -lt "$2" ]; }
f=${CODEX_HOME:-$HOME/.codex}/auth.json
[ -r "$f" ] || { echo "codex none"; exit 0; }
command -v curl >/dev/null 2>&1 || { echo "codex nocurl"; exit 0; }

t=$(tr -d '\n' <"$f" | sed -n 's/.*"tokens" *: *{\([^}]*\)}.*/\1/p')
tok=$(printf '%s' "$t" | sed -n 's/.*"access_token" *: *"\([^"]*\)".*/\1/p')
acc=$(printf '%s' "$t" | sed -n 's/.*"account_id" *: *"\([^"]*\)".*/\1/p')
case $tok in ""|*[!A-Za-z0-9._~+/=-]*) echo "codex none"; exit 0;; esac
case $acc in *[!A-Za-z0-9._-]*) acc=;; esac

# Share one answer between refreshes and widget instances, and stay quiet for 5 minutes after "too many requests"
c=${XDG_RUNTIME_DIR:-/tmp}/plasmetrics-codex-$(id -u)
if fresh "$c.wait" 300; then echo "codex http429"; exit 0; fi
if fresh "$c" "$ttl"; then cat "$c"; exit 0; fi

r=$({ printf 'header = "Authorization: Bearer %s"\n' "$tok"
      [ -n "$acc" ] && printf 'header = "ChatGPT-Account-Id: %s"\n' "$acc"; } \
    | curl -sS -m 15 -K - -H 'Accept: application/json' -H 'User-Agent: Plasmetrics' \
      -w '\n%{http_code}' https://chatgpt.com/backend-api/wham/usage 2>/dev/null)
code=$(printf '%s\n' "$r" | tail -n1)
case $code in
  200) { echo "codex ok"; printf '%s\n' "$r" | sed '$d'; } | tee "$c.$$" >/dev/null; [ "$(wc -l <"$c.$$")" -gt 2 ] && mv "$c.$$" "$c" || rm -f "$c.$$"; cat "$c" 2>/dev/null;;
  401|403) echo "codex expired";;
  429) : >"$c.wait"; echo "codex http429";;
  *) echo "codex http${code:-0}";;
esac
