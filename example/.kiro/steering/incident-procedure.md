---
name: incident-procedure
description: Step-by-step method for investigating an error, timeout or outage in Cat's Kitchen. Use when the user reports a failure, a 4xx/5xx, slowness, or asks "why".
inclusion: auto
---

# Incident investigation procedure

Follow these steps in order. Do not skip to a fix.

1. **Scope.** Ask for the time window and team if not given. Default: last 15 minutes.
2. **Symptoms.** In the frontend log group, find errors for the window. Group by `status` and `path`.
3. **Trace.** Take one failing `request_id` and fetch every line with it from BOTH log groups.
4. **Compare.** Frontend status vs backend status for the same `request_id`
   (e.g. frontend 504 + backend 499 = timeout cascade; frontend 502 = backend unreachable).
5. **Dig down.** Backend error pointing at the database -> check DB log group and DB state.
   Connection timeouts -> check security groups. Connection refused -> check the DB is running.
6. **What changed?** Query CloudTrail for write events in the 30 minutes before the first error.
7. **Report.** Give: timeline, evidence (quote log lines with `request_id`), root cause,
   confidence (high/medium/low), and a suggested fix for a human to apply.

Never state a root cause without at least one log line or CloudTrail event as evidence.
If the evidence is incomplete, say what is missing.
