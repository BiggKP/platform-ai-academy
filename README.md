# AI Academy: AI for Infra Operations

Course materials for the TPIT AI Academy program **AI for Infra Operations**, run by the Platform team.
Use this repo during the sessions and keep it as a reference afterwards.

> **Before Session 2:** Follow the [Setup Guide](SETUP.md) to install the required tools and check your AWS access.

By the end of the course you will build your own AI agent with [Kiro](https://kiro.dev) that helps with a
real ops task: security, incident investigation, or script automation.

## Contents

- [Course overview](#course-overview)
- [How you pass](#how-you-pass)
- [Before Session 2](#before-session-2)
- [The practice app: Cat's Kitchen](#the-practice-app-cats-kitchen)
- [Tracing a request](#tracing-a-request)
- [Working in the shared sandbox](#working-in-the-shared-sandbox)
- [Prompting Kiro for an investigation](#prompting-kiro-for-an-investigation)
- [Starter troubleshooting agent](#starter-troubleshooting-agent)
- [Getting help](#getting-help)

## Course overview

| Session | Topic | Hours | Format | Instructors |
|---|---|:---:|---|---|
| Common | Security & Responsible AI Use (all faculties) | 2 | Lecture | Academy |
| 1 | AI Foundations, Kiro & Agentic AI for Infra | 3 | Lecture + hands-on lab | AWS Thailand |
| 2 | Log Analysis & Incident Troubleshooting with Kiro | 2 | Lecture + workshop | Nut, Mew, Big |
| 3 | Scripting Automation & IaC with Kiro | 2 | Lecture + workshop | Nut, Mew, Big |
| 4 | Ideas Sharing, Showcase & Future Vision | 2 | Showcase & discussion | Nut, Mew, Big |

**Instructors**

| Name | Role |
|---|---|
| Sunhanut (Nut) | Program lead, coordination |
| Supasin (Mew) | Sandbox & infra (Terraspace) |
| Kaiwan (Big) | Script automation |

## How you pass

1. **Build** your own AI agent with Kiro for a real ops task: security, incident investigation, or script automation.
2. **Demo** it working in Session 4, and share how it could cut repeat work in your team.
3. **Attend** at least 80% of the sessions.

You are evaluated on your presentation and demo. There is no certification exam.

## Before Session 2

- [ ] Kiro installed and signed in ([kiro.dev](https://kiro.dev))
- [ ] AWS CLI v2 installed, and you can sign in to the **academy sandbox** with the profile your instructors give you
- [ ] `aws sts get-caller-identity --profile workshop` returns your read-only IAM user (see [Setup Guide](SETUP.md))
- [ ] Your AWS console and CLI are set to **Asia Pacific (Singapore) `ap-southeast-1`**, where the sandbox runs
- [ ] You can open the Cat's Kitchen URL shared in class
- [ ] Common Course (Security & Responsible AI Use) completed

If any step fails, tell an instructor before the session. Setup problems are much faster to fix ahead of time.

## The practice app: Cat's Kitchen

**ครัวเหมียว (Cat's Kitchen)** is a small Thai restaurant app that runs in the academy sandbox. It is built to
break in realistic ways, so you can practise finding out why with Kiro.

```
Browser ──▶ ALB (public) ──▶ frontend (ECS, private) ──x-request-id──▶ backend (ECS, private)
                                                                         ├──▶ Aurora PostgreSQL (orders)
                                                                         └──▶ NAT ──▶ public cat / food APIs
```

- **frontend** serves the web page and forwards each request to the backend. It waits at most **3 seconds**,
  then gives up with `504`.
- **backend** is not reachable from the internet; only the frontend can call it (through ECS Service Connect).
- Both services write **one JSON line per request** to CloudWatch Logs, kept for 14 days:

| Service | Log group |
|---|---|
| frontend | `/apps/demo-app/demo-frontend-service/sandbox` |
| backend | `/apps/demo-app/demo-backend-service/sandbox` |

### What each part of the page does

| On the page | Request | What to expect |
|---|---|---|
| Place order (pick a dish and quantity) | `POST /orders` | Saves your order to the database (`201`) |
| Orders table | `GET /orders` | Latest orders from the whole class. Tick **Only mine** to see your team's |
| รายงานยอดขาย | `GET /report` | Totals per dish, read from the database |
| เชฟแมวประจำวัน | `GET /cat` | A random cat photo. About 1 in 5 fail |
| อาหารไทย | `GET /food` | Thai dishes from a public recipe API. About 2 in 5 fail |
| เชฟแมวช้า | `GET /slowcat` | The backend takes 3.5 s, so the frontend returns `504` |
| ออเดอร์หาย | `GET /demo4xx` | Always `404` |
| ออเดอร์ไหม้ | `GET /demo5xx` | The backend waits 5 s, then `503`. The frontend gives up first, so you see `504` |

The random failures and slow requests are **on purpose**. Use them to practise before the real incidents start.
Notice that a failing `/cat` or `/food` request also waits 4–5 s in the backend, so on the page it usually
shows as a `504`, not the error the backend chose. The backend log tells you what really happened.

> **Outside class hours** the database is stopped automatically (at 18:00 and at midnight, Bangkok time) to save
> cost. Ordering, the Orders table and the report will fail while it is stopped. That is expected, not an incident.

## Tracing a request

Every request gets a **request ID**. The page shows the first 8 characters on each ticket (`#7e9407ff`);
**Copy ID** copies the full ID. The same ID appears in the frontend log, the backend log, and the `orders` table.

**Choose your team** (`team01` to `team10`) on the page before you order; ordering is blocked until you do.
The page remembers your choice. The frontend adds it to its logs as `team`, and it is saved with your order,
so you can find your own requests among everyone else's.

### Log fields

| Field | Frontend | Backend | Meaning |
|---|:---:|:---:|---|
| `timestamp` | ✓ | ✓ | When the line was written (UTC) |
| `service` | ✓ | ✓ | `frontend` or `backend` |
| `level` | ✓ | ✓ | `info`, `warn` or `error` |
| `request_id` | ✓ | ✓ | Joins one request across both services |
| `team` | ✓ | | Team chosen on the page |
| `path`, `method`, `status` | ✓ | ✓ | What was called and the result |
| `latency_ms` | ✓ | ✓ | Total time for the request |
| `upstream_status`, `upstream_latency_ms` | ✓ | | What the backend returned, as seen by the frontend |
| `error` | ✓ | | Why the frontend failed, e.g. `upstream timeout after 3000ms` |

### Status codes worth knowing

| Code | Where | Usually means |
|---|---|---|
| `499` | backend | The frontend gave up before the backend answered |
| `502` | frontend | The frontend could not reach the backend at all |
| `503` | either | A service said it cannot handle the request |
| `504` | frontend | The backend was too slow (more than 3 s) |

> **Example.** A เชฟแมวช้า (slow cat) request shows `504` on the page. The frontend log says `upstream timeout after 3000ms`.
> The backend log for the same `request_id` shows `499`, and later finishes on its own. The backend is not broken;
> the timeout is the root cause.

### Useful CloudWatch Logs Insights queries

Open **CloudWatch → Logs Insights** in `ap-southeast-1` and pick the log group(s) named above.

Your team's errors in the last 15 minutes (frontend log group):

```
fields @timestamp, request_id, path, status, latency_ms, upstream_status, error
| filter team = "team03" and status >= 500
| sort @timestamp desc
| limit 50
```

Everything about one request (select both the frontend and backend log groups):

```
fields @timestamp, service, path, status, latency_ms, message, error
| filter request_id = "<paste the full request ID>"
| sort @timestamp asc
```

Errors per path, per minute (shows when a problem started):

```
fields @timestamp, path, status
| filter status >= 500
| stats count(*) as errors by bin(1m), path
```

## Working in the shared sandbox

All 20 students share **one** environment. What you do can affect everyone, so please follow these rules.

1. **You are read-only by default.** Your profile can read logs, ECS, ALB and CloudTrail, but cannot change anything.
2. **One team fixes per round.** When it is your team's turn, an instructor gives you the operator role.
   Everyone else writes their proposed fix in their report without running it.
3. **Keep Kiro's command approval on.** Read every command before you approve it. If you would not run it
   yourself, do not approve it.
4. **Stay in the incident's time window.** Each round starts at a time your instructor announces. Older errors
   in the logs may belong to an earlier round.
5. **No real data.** Do not paste real customer data, production logs, passwords or keys into Kiro or into
   this sandbox.

### Each incident round (about 15 minutes)

| Time | What happens |
|---|---|
| 0:00 | Instructor starts the incident and announces the start time |
| 0:01–0:08 | All teams investigate with Kiro (read-only) |
| 0:08–0:10 | Teams post their root cause and proposed fix |
| 0:10–0:13 | One team applies the fix on screen |
| 0:13–0:15 | Everyone checks the logs to confirm recovery, then the instructor resets |

### Incident report

Fill this in for every round.

```markdown
## Incident: <short name>
- Team:
- Symptom: what users saw, and since when
- Timeline: key events with times (UTC)
- Root cause: one sentence
- Evidence: the exact log lines or CloudTrail events that prove it
- Fix: what to change (command or Terraform), and who should run it
- Prevention: what would stop this happening again
- Where Kiro was wrong (if anywhere):
```

## Prompting Kiro for an investigation

Give Kiro the context it cannot guess: **what** is broken, **when** it started, **which** logs to read, and
**what you want back**. Ask for evidence, not just an answer.

**Weak**

> The site is broken, what's wrong?

**Better**

> Users of Cat's Kitchen are getting 502 errors since about 10:40 (UTC+7). Using the academy profile, read the
> `/apps/demo-app/demo-frontend-service/sandbox` and `/apps/demo-app/demo-backend-service/sandbox` from 10:30 to now, and CloudTrail for the same window. Build a timeline,
> list possible causes ranked by evidence, and quote the log lines or CloudTrail events behind each one.
> Do not change anything; propose the fix only.

More prompts to try:

- "Trace request ID `<id>` across both services and tell me where the time went."
- "Compare the error rate before and after 10:40. What changed in CloudTrail in that window?"
- "Which ECS tasks stopped in the last 30 minutes, and what was the stopped reason?"
- "Is this error coming from the frontend, the backend, or the database? Show me how you know."

Kiro can be wrong or confidently guess. Check every root cause against the evidence it quotes.

## Starter troubleshooting agent

In Session 2 you turn your investigation steps into a reusable agent. Save the file below as
`.kiro/steering/troubleshooting.md` in your Kiro workspace, then adapt it to your own systems.
This is a good starting point for your Session 4 agent.

```markdown
# Infra troubleshooting agent

You help investigate incidents in AWS-hosted services. You investigate first and never change anything
unless the user explicitly asks you to apply a specific fix.

## Procedure
1. Ask for: the affected service, the time window, and the symptom, if the user has not given them.
2. Read the application logs (CloudWatch Logs) for that window.
3. Check CloudTrail for changes from 30 minutes before the window until now.
4. Check ECS service events and stopped tasks for the affected services.
5. Build a timeline, then list possible causes ranked by the evidence for each.
6. Never state a root cause without quoting the log line or event that supports it.
7. Propose a fix as a command or a Terraform change. Ask before running any command that changes a resource.

## Output
- Symptom
- Timeline
- Root cause + evidence
- Fix
- Prevention

## Rules
- Use the AWS profile named by the user; default to the read-only profile.
- Never print secrets, keys or passwords, even if you find them in logs.
```

## Getting help

- During the session: raise your hand or post in the course chat group.
- Setup problems before a session: message any instructor.
- Something wrong in this README: open an issue or a pull request in this repo.
