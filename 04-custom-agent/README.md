# Lab 04 – Custom agent: your incident investigator

**Goal:** package the tools (Lab 01), rules (Lab 02) and skills (Lab 03) into one reusable agent, then use it on a real incident.

A **custom agent** is a saved role: a prompt, which tools it may use, which files it loads, and what it may do without asking.

## 1. Read the agent definition
[`../.kiro/agents/incident-investigator.md`](../.kiro/agents/incident-investigator.md) (IDE)
and [`incident-investigator.json`](../.kiro/agents/incident-investigator.json) (CLI) describe the same agent.

| Setting | Meaning here |
|---|---|
| `includeMcpJson: true` | reuse the servers from `.kiro/settings/mcp.json` (no copy-paste, no second place for credentials) |
| `tools` | only file reading plus `@cloudwatch`, `@cloudtrail`, `@aws-api` |
| `resources` | load three steering files at start (`cats-kitchen`, `incident-procedure`, `incident-report`), and make the skills available (loaded on demand) |
| prompt | read-only, evidence for every claim, humans apply fixes |
| `allowedTools` (CLI file) | tools it may use without asking. Read-only ones only; everything else still asks |
| `welcomeMessage` (CLI file) | first thing it says |

> **Least privilege, twice.** The agent only has the tools it needs, and your IAM role is read-only. Neither replaces the other.

## 2. Select the agent
- **IDE:** open the agent selector in the Kiro chat and choose `incident-investigator`.
- **CLI:** from the repo root (the folder that contains `.kiro/`) run `kiro-cli chat --agent incident-investigator`.

If it does not appear, check the file is directly in `.kiro/agents/`, the front matter is valid, then reload the window.
(Kiro versions differ on the exact format and field names. If the file is rejected, ask an instructor and try the other format.)

## 3. Smoke test
```
Which tools do you have? Can you change anything in AWS?
```
It should list CloudWatch, CloudTrail and AWS API tools (and no Cost Explorer), and say it is read-only.

### See the scope in action
This uses the script from [Lab 03](../03-skills/README.md) step 5. If you skipped that step, you can still see the "no shell tool" answer, but not the comparison with the default agent.

In the same chat, ask:
```
I clicked เชฟแมวช้า and got a 504 in the last 10 minutes. Run scripts/window.sh 10 to get the time window.
```
Expected: it says it has **no shell tool**, so it cannot run the script. It may still do the search using the
CloudWatch tool and a time range it works out itself. That is the design, not a bug.

The `slow-request-check` skill from Lab 03 is still loaded, but a skill can only use the tools the agent has.
Switch to the default agent and ask the same question: there the script runs (after you approve the command).
To let the investigator run it, you would have to add a shell tool to `tools`. Do that only if you accept the extra risk.

## 4. Investigate (practice)
Use the practice endpoints on the Cat's Kitchen page, then ask:

1. `I clicked เชฟแมวช้า and got a 504. Explain what happened. My team is teamXX, last 10 minutes.`
2. `/demo5xx gives 504 on the page but the backend logged 503. Why do they differ?`
3. `Is /food failing more often than /cat? Show numbers.`
4. `Check ECS CPU and memory, ALB 5xx and latency, and Aurora CPU and connections for the last 30 minutes. Does anything look overloaded?`

Check every answer: did it quote a `request_id`? Can you find the same lines in CloudWatch yourself?

## 5. Investigate (the real incident)
During the workshop round, the instructors break something in the shared sandbox. Do not guess the cause.

1. Tell the agent your team, the time window and the symptom.
2. Let it follow the procedure: symptoms → trace a `request_id` → compare services → dig down → metrics → what changed (CloudTrail) → report.
3. **You verify** its claim with at least one log line or event you looked at yourself.
4. Finish with:
   ```
   #incident-report Write the report for this incident.
   ```
5. Submit the report as your team's deliverable (see the root README for the template and passing criteria).

## 6. Extra: more agents, one job each
The same recipe gives you agents for other jobs. Two more are in `.kiro/agents/`. Each has its own tools and loads **one** manual steering file, so it only follows those rules when you pick that agent.

| Agent | Tools | Rules it loads | Try this |
|---|---|---|---|
| `aws-cost-reviewer` | `@cost-explorer`, `@aws-documentation` | `cost-report.md` | `Check cost last week` |
| `aws-security-reviewer` | `@aws-api`, `@aws-documentation`, `@cloudtrail` | `aws-security-baseline.md` | `Check ECS security and conclude` |

Select one in the agent selector (IDE) or run `kiro-cli chat --agent aws-cost-reviewer` (CLI), then use the prompt above.
Compare with `incident-investigator`: different tools, different rules, same read-only design.
Cost Explorer calls cost USD 0.01 each, so do not loop on them. As always, check the numbers and evidence yourself.

## 7. Make it yours
Copy the agent to `my-investigator.md`, change the name and add one rule (for example "answer in Thai" or
"always end with 3 next checks"). Confirm the new behaviour.

## Checkpoint
- [ ] The agent is selectable and lists only its allowed tools
- [ ] It traced a request across both log groups with the same `request_id`
- [ ] You verified one claim yourself
- [ ] You produced an incident report in the template format

## Limits to remember
- Kiro permission settings are **client-side controls**. They reduce mistakes; they are not security boundaries. IAM is.
- The agent can be confidently wrong. Evidence you checked is worth more than a fluent explanation.
- Do not paste secrets or personal data into chats.
