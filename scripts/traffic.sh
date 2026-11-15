#!/usr/bin/env bash
# Instructor tool: send steady, realistic background traffic to Cat's Kitchen so that
# logs and metrics are never empty during a lab or an incident round.
#
# Usage:  scripts/traffic.sh <base-url> [options]
#   <base-url>          ALB or app URL, e.g. http://main-alb-sandbox-123.ap-southeast-1.elb.amazonaws.com
#   -i, --interval SEC  seconds between requests (default 3)
#   -p, --post-every N  send one POST /api/orders every N requests; 0 = never (default 10)
#   -t, --team NAME     send this x-team value (default: none, so the log has no `team` field)
#   -n, --count N       stop after N requests (default: run until Ctrl+C)
#       --dry-run       print the requests instead of sending them
#
# Requests carry the user agent "traffic-generator", so students can tell them apart:
#   filter user_agent != "traffic-generator"   (frontend log group)
# Stop it when the database is stopped (outside class hours); POST/GET orders would only add expected errors.
set -u

interval=3; post_every=10; team=""; count=0; dry=0; url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -i|--interval)  interval="$2"; shift 2 ;;
    -p|--post-every) post_every="$2"; shift 2 ;;
    -t|--team)      team="$2"; shift 2 ;;
    -n|--count)     count="$2"; shift 2 ;;
    --dry-run)      dry=1; shift ;;
    -h|--help)      sed -n '2,15p' "$0"; exit 0 ;;
    -*)             echo "unknown option: $1" >&2; exit 2 ;;
    *)              url="${1%/}"; shift ;;
  esac
done
[ -n "$url" ] || { echo "usage: $0 <base-url> [options]  (see --help)" >&2; exit 2; }

# Weighted mix of GET routes (same spirit as the page's rush hour, with fewer slow/failing ones).
ROUTES=(orders orders orders report report cat cat cat food food slowcat demo4xx demo5xx)
DISHES=("ผัดไทย" "ต้มยำกุ้ง" "แกงเขียวหวาน" "ข้าวมันไก่" "ส้มตำ" "ผัดกะเพรา")

new_id() {  # x-request-id must match [A-Za-z0-9-]{8,64}
  if command -v uuidgen >/dev/null 2>&1; then uuidgen | tr 'A-Z' 'a-z'
  else printf '%08x-%04x-%04x\n' $((RANDOM * RANDOM)) $RANDOM $RANDOM; fi
}

send() {  # send <METHOD> <route> [json-body]
  local method="$1" route="$2" body="${3:-}" id; id="$(new_id)"
  local args=(-s -o /dev/null -m 8 -w "%{http_code} %{time_total}s" -X "$method"
              -A traffic-generator -H "x-request-id: $id")
  [ -n "$team" ] && args+=(-H "x-team: $team")
  [ -n "$body" ] && args+=(-H "content-type: application/json" -d "$body")
  if [ "$dry" = 1 ]; then
    echo "$(date +%T) $method /api/$route id=$id${team:+ team=$team}${body:+ body=$body}"
  else
    echo "$(date +%T) $method /api/$route id=$id -> $(curl "${args[@]}" "$url/api/$route" 2>/dev/null || echo "curl failed")"
  fi
}

n=0
trap 'echo; echo "stopped after $n requests"; exit 0' INT TERM
while :; do
  n=$((n + 1))
  if [ "$post_every" -gt 0 ] && [ $((n % post_every)) -eq 0 ]; then
    dish="${DISHES[$((RANDOM % ${#DISHES[@]}))]}"
    send POST orders "{\"item\":\"$dish\",\"quantity\":$((RANDOM % 3 + 1))}"
  else
    send GET "${ROUTES[$((RANDOM % ${#ROUTES[@]}))]}"
  fi
  [ "$count" -gt 0 ] && [ "$n" -ge "$count" ] && break
  sleep "$interval"
done
