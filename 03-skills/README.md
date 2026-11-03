# Lab 03 – Skills: reusable know-how that loads on demand

**Goal:** Kiro uses a saved, reusable skill (a set of Logs Insights queries) only when your request needs it, instead of you pasting the same queries every time.

A **skill** is a folder with a `SKILL.md` file that teaches Kiro one procedure or capability. Skills follow the
open [Agent Skills](https://agentskills.io) standard, so the same folder can work in other tools too.

## Steering or skill?

| | Steering (Lab 02) | Skill (this lab) |
|---|---|---|
| Holds | Facts, rules, standing context | A task with steps, templates, or scripts |
| Loaded | By `inclusion` mode (`always`, `auto`, ...) | Only the `name` + `description` at start; the full file when the task matches |
| Can include | One Markdown file | A folder: `SKILL.md`, plus optional `references/`, `scripts/`, `assets/` |
| Example | "Log groups are X and Y; times in UTC+7" | "How to write the right Logs Insights query for each question" |

Rule of thumb: *"Kiro should always know this"* → steering. *"Kiro should know how to do this when asked"* → skill.
Because only the description is loaded up front, skills keep your context window small.

## 1. Read the example skill
It is in the `.kiro/` folder you copied in Lab 01 (if you skipped it, run `cp -R example/.kiro .` from the repo root).
Open [`../.kiro/skills/logs-insights-queries/SKILL.md`](../.kiro/skills/logs-insights-queries/SKILL.md).

```
.kiro/skills/
└── logs-insights-queries/
    └── SKILL.md
```

| Part | Purpose |
|---|---|
| Folder name | Must match `name` in the front matter |
| `name` | Lowercase letters, numbers and hyphens only |
| `description` | **The trigger.** Kiro reads this to decide when to load the skill. Say what it does and "Use when…" |
| Body | The instructions Kiro follows once the skill is loaded |

Skills can live in two places:

| Location | Scope |
|---|---|
| `.kiro/skills/` in the workspace | This project only, shared with the team through git |
| `~/.kiro/skills/` | All your workspaces, only on your machine |

## 2. See it activate
Open a **new** chat in this workspace and ask:

> Show me the failure rate per path for the last hour. Is /food worse than /cat?

Look at: did Kiro say it is using the `logs-insights-queries` skill (or read its `SKILL.md`)? Did it show the
query it ran? Did it include `request_id` in the result?

Then ask something unrelated, such as `What is the Aurora cluster named?`, and notice the skill is **not** used.

## 3. See what a vague description costs
In `.kiro/skills/logs-insights-queries/SKILL.md`, replace the whole `description` line in the front matter with:

```markdown
description: Queries.
```

Open a **new** chat and ask the same question as in step 2:

> Show me the failure rate per path for the last hour. Is /food worse than /cat?

Kiro is now much less likely to use the skill, because the description gives it nothing to match against.
It may answer without the skill, or write its own query that misses rules like "include `request_id`".

Then put the original description back:

```markdown
description: Ready-made CloudWatch Logs Insights queries for Cat's Kitchen (errors per path, one request across both services, slow requests, team filter). Use when the user asks to search, count, trace or compare log lines, or asks for a Logs Insights query.
```

Open another new chat, ask again, and confirm the skill is used again.

## Another example: `metrics-check`
[`../.kiro/skills/metrics-check/SKILL.md`](../.kiro/skills/metrics-check/SKILL.md) shows a skill that
tells Kiro which CloudWatch metrics to read for ECS, the ALB and Aurora, and how to find the real resource names first.
Ask: `Is anything overloaded right now? Check ECS, the ALB and the database.` Notice it looks up resource names
with read-only calls before querying metrics, and shows the namespace and dimensions it used.

## 4. Write your own skill
Create `.kiro/skills/slow-request-check/SKILL.md`:

```markdown
---
name: slow-request-check
description: Checks whether a slow request was caused by the frontend 3s timeout. Use when the user reports a 504, a timeout, or "slow" on any Cat's Kitchen page.
---

# Slow request check

1. Ask for the `request_id` if the user has not given it.
2. Fetch the frontend and backend log lines for that `request_id`.
3. Compare:
   - frontend `504` with `upstream timeout after 3000ms` and backend `499` → the frontend gave up first.
     The backend is not broken; the 3s timeout is the root cause.
   - backend latency under 3000ms but frontend still failed → look at the network path or the frontend itself.
4. Answer in three lines: what the user saw, what the logs say, why.
   Quote the log line for each.
```

Start a new chat and ask: `I clicked เชฟแมวช้า and got a 504. Why?` Check that Kiro followed your three steps.

## 5. Try it with a script (optional)
A skill folder can carry a script that Kiro runs for the user. Create `.kiro/skills/slow-request-check/scripts/window.sh`:

```bash
#!/usr/bin/env bash
# Print the start and end of the last N minutes as epoch seconds (default 15)
n="${1:-15}"
echo "start=$(date -v-"${n}"M +%s) end=$(date +%s)"
```

Then edit `slow-request-check/SKILL.md` so the skill uses the script. Add this as a new step 1 in the list, and
renumber the other steps:

```markdown
1. If the user gives a time window like "the last 10 minutes" and no `request_id`, run
   `bash scripts/window.sh <minutes>` to get the start and end times, and use them for the log search.
```

(`date -v` in the script works on macOS. On Linux use `date -d "-${n} min" +%s`.)

**Open a new chat first.** Kiro reads a skill when the chat starts, so a chat that was already open will not see your edit.
Then ask something that matches the skill's description, because the skill only loads when your request does:

> I clicked เชฟแมวช้า and got a 504 in the last 10 minutes. Why?

Kiro should load `slow-request-check` and ask to run `bash scripts/window.sh 10`. Read the command before you approve it,
like any other command. If it never asks, check that you opened a new chat and that the request mentions a 504 or a timeout.

## Good skills vs bad skills
- One skill, one job. Split a skill that does three things.
- The `description` is the most important line. Start with what it does, then "Use when…" with the words users really say.
- Short, numbered, testable steps ("quote the log line") beat long advice.
- Keep `SKILL.md` small. Move long reference material into `references/` and link to it.
- Never put secrets, keys or real customer data in a skill. It is plain text in your repo.
- A skill guides Kiro, it does not enforce anything. Real limits come from IAM.

## Checkpoint
- [ ] Kiro used `logs-insights-queries` for a log question and not for an unrelated one
- [ ] You saw a vague description make the skill harder to trigger
- [ ] Your own `slow-request-check` skill followed its steps

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| Skill never triggers | Description too vague, or the folder name does not match `name`. Check the Kiro panel for loaded skills |
| Skill not listed | File is not named exactly `SKILL.md`, or the front matter is missing `name` / `description` |
| Edited a skill but nothing changed | Skills are read when the chat starts. Open a **new** chat after every edit |
| Skill's script never runs | The request did not match the skill's `description`, so the skill was not loaded. Ask in words the description uses |
| Custom agent ignores the skill | The agent's `resources` does not include `skill://.kiro/skills/**/SKILL.md` (see Lab 04) |

> Skill support and menu names differ slightly between Kiro versions. If something does not match, tell an instructor.

Next: [Lab 04 – Custom agent](../04-custom-agent/README.md)
