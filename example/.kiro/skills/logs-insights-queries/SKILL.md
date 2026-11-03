---
name: logs-insights-queries
description: Ready-made CloudWatch Logs Insights queries for Cat's Kitchen (errors per path, one request across both services, slow requests, team filter). Use when the user asks to search, count, trace or compare log lines, or asks for a Logs Insights query.
---

# Logs Insights queries for Cat's Kitchen

Log groups (region `ap-southeast-1`):

- frontend: `/apps/demo-app/demo-frontend-service/sandbox`
- backend: `/apps/demo-app/demo-backend-service/sandbox`

Fill in the time window first. If the user did not give one, ask. Default to the last 15 minutes.
Run the query with the CloudWatch tool, then show the query you ran and quote the rows that support your answer.

## Errors for one team (frontend)

```
fields @timestamp, request_id, path, status, latency_ms, upstream_status, error
| filter team = "<team>" and status >= 500
| sort @timestamp desc
| limit 50
```

## Everything about one request (both log groups)

```
fields @timestamp, service, path, status, latency_ms, message, error
| filter request_id = "<full request id>"
| sort @timestamp asc
```

## When did the errors start? (errors per minute, per path)

```
fields @timestamp, path, status
| filter status >= 500
| stats count(*) as errors by bin(1m), path
```

## Slowest requests (frontend)

```
fields @timestamp, request_id, path, latency_ms, status
| filter latency_ms > 3000
| sort latency_ms desc
| limit 20
```

## Failure rate per path (use for "is /food worse than /cat?")

```
fields path, status
| stats count(*) as total, sum(status >= 500) as failed by path
| sort failed desc
```

## Rules

- Always include `request_id` in the fields you return, so the user can verify the rows.
- Use `team` only on the frontend log group. The backend lines do not have it.
- Keep the time window narrow. Wide windows are slow and mix in older incidents.
