---
inclusion: manual
---

# Incident report format

Use this exact structure when asked for an incident report.

## Summary
One or two sentences: what broke, for whom, for how long.

## Timeline (UTC)
| Time | Event | Evidence |
|---|---|---|

## Root cause
What actually caused it, and the evidence (log lines with `request_id`, CloudTrail event IDs).

## Impact
Which endpoints/users, error rate if known.

## Fix / mitigation
What a human should do. Do not claim it was applied.

## Follow-ups
Alert, monitoring or runbook improvements.
