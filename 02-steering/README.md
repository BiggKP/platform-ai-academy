# Lab 02 – Steering: give Kiro context and rules

**Goal:** Kiro knows how Cat's Kitchen works and follows our investigation method without being told every time.

**Steering files** are Markdown files in `.kiro/steering/`. Kiro reads them as standing instructions.
How a file is loaded is set by the `inclusion` mode in its front matter:

| Mode | Loaded | Use for |
|---|---|---|
| `always` | every conversation | facts and rules that always apply |
| `fileMatch` | when a matching file is open | rules for specific file types |
| `auto` | when your request matches its `description` | procedures and playbooks |
| `manual` | only when you reference it (e.g. `#incident-report`) | templates you want on demand |

## 1. Read the three examples
In [`../.kiro/steering/`](../.kiro/steering/):

| File | Mode | Purpose |
|---|---|---|
| `cats-kitchen.md` | `always` | Architecture, log groups, fields, status codes, known noise |
| `incident-procedure.md` | `auto` | The method: scope → trace → compare → what changed → report |
| `incident-report.md` | `manual` | Report template, used only on request |

Note `incident-procedure.md` has a `name` and a good `description`. For `auto` files the description is how Kiro decides to load it, so write it as "use when…".

## 2. See the difference
Open a **new** chat in `example/` and ask this **without** any hand-holding:

> The frontend shows 504 on /slowcat. Why?

Look at: does Kiro know the log group names? Does it trace by `request_id`? Does it cite evidence?

Now temporarily rename `.kiro/steering` to `.kiro/steering.off`, open a new chat, ask the same question, and compare.
Rename it back afterwards.

## 3. Use the manual file
In a new chat:
```
#incident-report Write an incident report for the /slowcat 504.
```
The answer should follow the template's headings.

## 4. Write your own rule
Create `.kiro/steering/team.md`:

```markdown
---
inclusion: always
---

# Our team
- We are team01. Always filter logs with `team = "team01"` unless I say otherwise.
- Show times in Bangkok time (UTC+7) as well as UTC.
```
Replace `team01` with your team. Ask Kiro: `Show my team's errors from the last 15 minutes.`
Check that it applied your filter and both time zones.

## Good steering vs bad steering
- Short, specific, testable ("quote the log line") beats long and vague ("be careful").
- Put **facts** in `always`, **procedures** in `auto`, **templates** in `manual`.
- Never put secrets, keys or real customer data in steering files; they are plain text in your repo.
- Steering guides Kiro, it does not enforce anything. Real limits come from IAM.

## Checkpoint
- [ ] Kiro answered differently with and without steering
- [ ] `#incident-report` produced the template's headings
- [ ] Your own `team.md` rule was applied

Next: [Lab 03 – Skills](../03-skills/README.md)
