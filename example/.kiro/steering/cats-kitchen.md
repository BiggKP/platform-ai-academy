---
inclusion: always
---

# Cat's Kitchen (ครัวเหมียว) – sandbox facts

Region: `ap-southeast-1`. AWS profile: `workshop` (read-only).

## Architecture
Browser -> public ALB -> frontend (ECS) -> backend (ECS, private) -> Aurora PostgreSQL.
The backend also calls public cat/food APIs through a NAT gateway.
The frontend gives up on the backend after 3 seconds and returns 504.

## Logs (CloudWatch Logs, JSON, one line per request)
- frontend: `/apps/demo-app/demo-frontend-service/sandbox`
- backend: `/apps/demo-app/demo-backend-service/sandbox`
- database: `/aws/rds/cluster/demo-app-db-cluster-sandbox/postgresql`

Fields: `timestamp`, `service`, `level`, `request_id`, `method`, `path`, `status`, `latency_ms`.
Frontend only: `team`, `upstream_status`, `upstream_latency_ms`, `error`.
`request_id` joins one request across frontend and backend.

## Status codes
- 499 (backend): the frontend hung up before the backend answered.
- 502 (frontend): could not reach the backend.
- 503: a service refused the request.
- 504 (frontend): backend slower than 3 s.

## Known, expected noise (not incidents)
- `/cat` fails about 1 in 5, `/food` about 2 in 5, on purpose.
- `/slowcat`, `/demo4xx`, `/demo5xx` are practice endpoints.
- The database is stopped outside class hours, so DB-backed calls fail then.

## Ground rules
- Read-only: never run commands that create, change or delete AWS resources.
- Filter by our team (`team` field) and a time window before reading logs.
