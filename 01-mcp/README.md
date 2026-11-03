# Lab 01 – Connect Kiro to AWS with MCP

**Goal:** Kiro can query CloudWatch Logs, CloudTrail and (read-only) the AWS API.

**MCP** (Model Context Protocol) lets Kiro call external tools. Here, three AWS Labs servers run locally
on your machine and use *your* `workshop` profile. MCP does not give any access by itself:
**IAM decides what is allowed**, and your profile is read-only.

## 1. Check prerequisites
```bash
uvx --version
aws sts get-caller-identity --profile workshop
```
Both must succeed. If the second fails, stop and ask an instructor.

## 2. Look at the config
Open [`../.kiro/settings/mcp.json`](../.kiro/settings/mcp.json). It defines three servers:

| Server | What it gives Kiro |
|---|---|
| `cloudwatch` | Logs Insights queries, log groups, metrics, alarms |
| `cloudtrail` | "Who changed what, when" (management events) |
| `aws-api` | Read-only AWS CLI calls (`describe-*`, `list-*`) |

Things to notice:
- `AWS_PROFILE` / `AWS_API_MCP_PROFILE_NAME` = `workshop`: a profile **name**, never a key.
- `READ_OPERATIONS_ONLY=true` on `aws-api`: the server refuses write calls (a second lock, on top of IAM).
- `AWS_REGION` = `ap-southeast-1`: where the sandbox lives.

> **Do not add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` to this file.** It is easy to commit by accident.

## 3. Load it in Kiro
1. Open the `example/` folder in Kiro.
2. Open the **Kiro** panel → **MCP Servers** (or run the command *Kiro: Open workspace MCP config*).
3. Confirm the three servers appear and show as connected. The first start can take a minute while `uvx` downloads them.
4. If one fails, open its log/error, fix, and use the reload/restart button.

## 4. Try it
In a Kiro chat, ask:

1. `List the CloudWatch log groups whose name starts with /apps/demo-app.`
2. `Show the last 10 error lines from the backend log group.`
3. `Which CloudTrail write events happened in the last hour?`

Kiro asks for approval before calling a tool. Read the tool name and arguments, then approve.

### Prove it is read-only
Ask: `Stop the ECS service demo-backend using the aws-api tool.`
Expected: it **fails** (blocked by the server and/or IAM). That is the design, not a bug.

## Checkpoint
- [ ] 3 servers connected
- [ ] You got real log lines back from Kiro
- [ ] A write request was refused

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| Server stays red / `uvx: command not found` | `uv` not installed, or not on the PATH Kiro sees. Restart Kiro after installing |
| `AccessDenied` / empty results | Wrong profile or region. Re-run the `sts` command above |
| `ExpiredToken` | Credentials expired; refresh the `workshop` profile |
| Tool calls time out | Narrow the time range (e.g. last 15 minutes) |

Next: [Lab 02 – Steering](../02-steering/README.md)
