# Lab 01 – Connect Kiro to AWS with MCP

**Goal:** Kiro can query CloudWatch Logs, CloudTrail, Cost Explorer, the AWS documentation and (read-only) the AWS API.

**MCP** (Model Context Protocol) lets Kiro call external tools. Here, five AWS Labs servers run locally
on your machine and use *your* `workshop` profile. MCP does not give any access by itself:
**IAM decides what is allowed**, and your profile is read-only.

## 1. Set up the `workshop` profile
Kiro's MCP servers use an AWS CLI **profile**. You created the `workshop` profile in the [Setup Guide](../SETUP.md#set-up-aws-access).
Sign in (do this at the start of every session; the login expires after a few hours):

```bash
aws sso login --profile workshop
```

Your browser opens. Sign in and return to the terminal. You get temporary credentials, so no access key is stored in any file.
If the profile does not exist yet, run `aws configure sso --profile workshop` first (see the Setup Guide).

The SSO role must be **read-only** (instructors set this up for the academy sandbox). Its permission set should include
these AWS managed policies:

| Policy | Why |
|---|---|
| `ReadOnlyAccess` | `describe-*` / `list-*` calls for ECS, ALB, RDS (the `aws-api` server) |
| `CloudWatchLogsReadOnlyAccess` | Logs Insights queries on the Cat's Kitchen log groups |
| `AWSCloudTrail_ReadOnlyAccess` | "Who changed what" lookups |

Do not use admin credentials, the root user, or a role that can change resources.

## 2. Check prerequisites
```bash
uvx --version
aws sts get-caller-identity --profile workshop
```
Both must succeed. The second should show the academy read-only role in `Arn`
(for example `arn:aws:sts::<account>:assumed-role/AWSReservedSSO_<role>_.../<you>`). If it fails, stop and ask an instructor.

## 3. Look at the config
First copy the example Kiro config into your workspace. Run this from the **root of this repo** (the folder that contains `example/`):

```bash
cp -R example/.kiro .
```

This creates `./.kiro/` (MCP config, steering, skills and agents) next to the labs. Every lab uses this copy.

Now open [`../.kiro/settings/mcp.json`](../.kiro/settings/mcp.json). It defines five servers:

| Server | What it gives Kiro |
|---|---|
| `cloudwatch` | Logs Insights queries, log groups, metrics, alarms |
| `cloudtrail` | "Who changed what, when" (management events) |
| `aws-api` | Read-only AWS CLI calls (`describe-*`, `list-*`) |
| `cost-explorer` | Cost and usage data (used by the cost agent in Lab 04, Extra) |
| `aws-documentation` | Search and read AWS documentation pages |

Things to notice:
- `--with awscrt` on `cloudwatch` and `cloudtrail`: these two servers use the Python SDK (boto3), which needs `awscrt` only to read an `aws login` profile. It is harmless with SSO, so we leave it in. `aws-api` uses the AWS CLI and does not need it.
- `AWS_PROFILE` / `AWS_API_MCP_PROFILE_NAME` = `workshop`: a profile **name**, never a key.
- `READ_OPERATIONS_ONLY=true` on `aws-api`: the server refuses write calls (a second lock, on top of IAM).
- `AWS_REGION` = `ap-southeast-1`: where the sandbox lives.

> **Do not add `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` to this file.** It is easy to commit by accident.

## 4. Load it in Kiro
1. Open the **root folder of this repo** in Kiro (the folder that contains `.kiro/`, not `example/`).
2. Open the **Kiro** panel → **MCP Servers** (or run the command *Kiro: Open workspace MCP config*).
3. Confirm the five servers appear and show as connected. The first start can take a minute while `uvx` downloads them.
4. If one fails, open its log/error, fix, and use the reload/restart button.

## 5. Try it
In a Kiro chat, ask:

1. `List the CloudWatch log groups whose name starts with /apps/demo-app.`
2. `Show the last 10 error lines from the backend log group.`
3. `Which CloudTrail write events related with ECS and Aurora Database in the last hour?`

Kiro asks for approval before calling a tool. Read the tool name and arguments, then approve.

### Prove it is read-only
Ask: `Stop the ECS service demo-backend using the aws-api tool.`
Expected: it **fails** (blocked by the server and/or IAM). That is the design, not a bug.

## Checkpoint
- [ ] 5 servers connected
- [ ] You got real log lines back from Kiro
- [ ] A write request was refused

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| Server stays red / `uvx: command not found` | `uv` not installed, or not on the PATH Kiro sees. Restart Kiro after installing |
| `cloudwatch` / `cloudtrail` red, `aws-api` works. Error mentions `botocore[crt]` | `awscrt` missing from the server's `args`. Make sure `--with awscrt` is in `.kiro/settings/mcp.json` (see step 3), then reload the servers |
| `AccessDenied` / empty results | Wrong profile or region. Re-run the `sts` command above |
| `ExpiredToken` / `The SSO session ... has expired` | Your SSO login ended. Run `aws sso login --profile workshop` again, then reload the MCP servers in Kiro |
| `The SSO session associated with this profile is invalid` or `Missing the following required SSO configuration` | The profile was not created, or is incomplete. Run `aws configure sso --profile workshop` (see the Setup Guide) |
| Tool calls time out | Narrow the time range (e.g. last 15 minutes) |

Next: [Lab 02 – Steering](../02-steering/README.md)
