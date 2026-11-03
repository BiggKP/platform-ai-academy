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
| `resources` | load all steering files at start, and make the skills available (loaded on demand) |
| prompt | read-only, evidence for every claim, humans apply fixes |
| `allowedTools` (CLI file) | tools it may use without asking. Read-only ones only; everything else still asks |
| `welcomeMessage` (CLI file) | first thing it says |

> **Least privilege, twice.** The agent only has the tools it needs, and your IAM role is read-only. Neither replaces the other.

## 2. Select the agent
- **IDE:** open the agent selector in the Kiro chat and choose `incident-investigator`.
- **CLI:** from `example/` run `kiro-cli chat --agent incident-investigator`.

If it does not appear, check the file is directly in `.kiro/agents/`, the front matter is valid, then reload the window.
(Kiro versions differ on the exact format and field names. If the file is rejected, ask an instructor and try the other format.)

## 3. Smoke test
```
Which tools do you have? Can you change anything in AWS?
```
It should list CloudWatch, CloudTrail and AWS API tools, and say it is read-only.

## 4. Investigate (practice)
Use the practice endpoints on the Cat's Kitchen page, then ask:

1. `I clicked เชฟแมวช้า and got a 504. Explain what happened. My team is teamXX, last 10 minutes.`
2. `/demo5xx gives 504 on the page but the backend logged 503. Why do they differ?`
3. `Is /food failing more often than /cat? Show numbers.`

Check every answer: did it quote a `request_id`? Can you find the same lines in CloudWatch yourself?

## 5. Investigate (the real incident)
During the workshop round, the instructors break something in the shared sandbox. Do not guess the cause.

1. Tell the agent your team, the time window and the symptom.
2. Let it follow the procedure: symptoms → trace a `request_id` → compare services → what changed (CloudTrail).
3. **You verify** its claim with at least one log line or event you looked at yourself.
4. Finish with:
   ```
   #incident-report Write the report for this incident.
   ```
5. Submit the report as your team's Workshop 3 deliverable (see the root README for the template and passing criteria).

## 6. Make it yours
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
