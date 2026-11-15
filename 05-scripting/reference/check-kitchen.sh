#!/usr/bin/env bash
# check-kitchen.sh - read-only health check for the Cat's Kitchen sandbox.
#
# Checks: ECS services, ALB targets, Aurora status, the app's /api/health, recent ALB 5xx.
# Prints one line per check (OK / WARN / FAIL). Exit code: 0 = no FAIL, 1 = at least one FAIL.
# Only calls read-only AWS APIs (describe-*, get-*). It never changes anything.
#
# Usage: check-kitchen.sh [--profile NAME] [--region REGION] [--minutes N] [--url BASE_URL]
set -uo pipefail

PROFILE="workshop"; REGION="ap-southeast-1"; MINUTES=15; URL=""
CLUSTER="main-sandbox"; ALB="main-alb-sandbox"; DB="demo-app-db-cluster-sandbox"
SERVICES="demo-frontend-service-sandbox demo-backend-service-sandbox"
WARN_5XX=1; FAIL_5XX=50   # 5xx count in the window: >= WARN_5XX is WARN, >= FAIL_5XX is FAIL

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --region)  REGION="$2";  shift 2 ;;
    --minutes) MINUTES="$2"; shift 2 ;;
    --url)     URL="${2%/}"; shift 2 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

aws_() { aws --profile "$PROFILE" --region "$REGION" "$@"; }
iso()  { date -u -v-"$1"M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d "-$1 min" +%Y-%m-%dT%H:%M:%SZ; }

fails=0; warns=0
row() {  # row <OK|WARN|FAIL> <check> <detail>
  printf '%-5s %-34s %s\n' "$1" "$2" "$3"
  case "$1" in FAIL) fails=$((fails + 1)) ;; WARN) warns=$((warns + 1)) ;; esac
}

echo "Cat's Kitchen check  profile=$PROFILE region=$REGION window=${MINUTES}m"
echo "-----------------------------------------------------------------"

# 1. ECS: running tasks vs desired
for svc in $SERVICES; do
  if ! out=$(aws_ ecs describe-services --cluster "$CLUSTER" --services "$svc" \
        --query 'services[0].[status,desiredCount,runningCount]' --output text 2>&1); then
    row FAIL "ecs/$svc" "cannot read: $out"; continue
  fi
  set -- $out; status="${1:-None}"; desired="${2:-0}"; running="${3:-0}"
  if [ "$status" = "None" ]; then row FAIL "ecs/$svc" "service not found"
  elif [ "$desired" -eq 0 ]; then row WARN "ecs/$svc" "desired count is 0 (service is scaled down)"
  elif [ "$running" -ge "$desired" ]; then row OK "ecs/$svc" "$running/$desired tasks running"
  else row FAIL "ecs/$svc" "only $running/$desired tasks running"; fi
done

# 2. ALB: find it, then check target health
lb_arn=""; dns=""
if out=$(aws_ elbv2 describe-load-balancers --names "$ALB" \
      --query 'LoadBalancers[0].[LoadBalancerArn,DNSName]' --output text 2>&1); then
  set -- $out; lb_arn="${1:-}"; dns="${2:-}"
else
  row FAIL "alb/$ALB" "cannot read: $out"
fi
if [ -n "$lb_arn" ]; then
  tgs=$(aws_ elbv2 describe-target-groups --load-balancer-arn "$lb_arn" \
        --query 'TargetGroups[].TargetGroupArn' --output text 2>/dev/null)
  [ -z "$tgs" ] && row WARN "alb/targets" "no target groups found"
  for tg in $tgs; do
    name="${tg#*:targetgroup/}"; name="${name%%/*}"
    states=$(aws_ elbv2 describe-target-health --target-group-arn "$tg" \
             --query 'TargetHealthDescriptions[].TargetHealth.State' --output text 2>/dev/null)
    total=0; healthy=0
    for s in $states; do total=$((total + 1)); [ "$s" = "healthy" ] && healthy=$((healthy + 1)); done
    if [ "$total" -eq 0 ]; then row WARN "alb/tg/$name" "no registered targets"
    elif [ "$healthy" -eq "$total" ]; then row OK "alb/tg/$name" "$healthy/$total targets healthy"
    else row FAIL "alb/tg/$name" "$healthy/$total targets healthy"; fi
  done
fi

# 3. Aurora: stopped is expected outside class hours, so only WARN
if status=$(aws_ rds describe-db-clusters --db-cluster-identifier "$DB" \
      --query 'DBClusters[0].Status' --output text 2>&1); then
  case "$status" in
    available) row OK "aurora/$DB" "available" ;;
    stopped|stopping) row WARN "aurora/$DB" "$status (expected outside class hours)" ;;
    *) row FAIL "aurora/$DB" "status is $status" ;;
  esac
else
  row FAIL "aurora/$DB" "cannot read: $status"
fi

# 4. The app itself
base="${URL:-${dns:+http://$dns}}"
if [ -n "$base" ]; then
  code=$(curl -s -o /dev/null -m 5 -w '%{http_code}' "$base/api/health" 2>/dev/null || true)
  if [ "$code" = "200" ]; then row OK "app/api/health" "HTTP 200"
  else row FAIL "app/api/health" "HTTP ${code:-none} from $base"; fi
else
  row WARN "app/api/health" "no URL known (pass --url)"
fi

# 5. ALB 5xx in the window (the practice endpoints /demo5xx etc. cause some on purpose)
if [ -n "$lb_arn" ]; then
  sum=$(aws_ cloudwatch get-metric-statistics --namespace AWS/ApplicationELB \
        --metric-name HTTPCode_Target_5XX_Count --dimensions "Name=LoadBalancer,Value=${lb_arn#*:loadbalancer/}" \
        --start-time "$(iso "$MINUTES")" --end-time "$(iso 0)" --period $((MINUTES * 60)) \
        --statistics Sum --query 'Datapoints[0].Sum' --output text 2>/dev/null)
  [ -z "$sum" ] || [ "$sum" = "None" ] && sum=0
  sum=${sum%.*}
  if [ "$sum" -ge "$FAIL_5XX" ]; then row FAIL "alb/5xx last ${MINUTES}m" "$sum target 5xx"
  elif [ "$sum" -ge "$WARN_5XX" ]; then row WARN "alb/5xx last ${MINUTES}m" "$sum target 5xx"
  else row OK "alb/5xx last ${MINUTES}m" "0 target 5xx"; fi
fi

echo "-----------------------------------------------------------------"
echo "Result: $fails FAIL, $warns WARN"
[ "$fails" -eq 0 ]
