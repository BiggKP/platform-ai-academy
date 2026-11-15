# Lab 05 – Scripting: let Kiro write a health-check script

**Goal:** use Kiro to write a Bash script that checks the status of the Cat's Kitchen sandbox, then **review it before you run it**.
Everything here is read-only.

**Why this lab:** AI writes scripts fast, and sometimes it writes the wrong thing. The skill you practise here is *asking well,
reviewing carefully, and running safely*, not typing code.

> You do not need to know Bash well. You need to be able to read a short script and spot a command that changes something.

## 0. Check before you start
- You finished Labs 01 to 04, or at least copied `.kiro/` to your workspace root (see [Lab 01](../01-mcp/README.md#3-look-at-the-config)).
- `aws sts get-caller-identity --profile workshop` works. If your session expired, run `aws login --profile workshop`.
- If you copied `.kiro/` before today, copy it again so you get the new steering file: `cp -R example/.kiro .`

## 1. Read the safety rules
Open [`../.kiro/steering/script-safety.md`](../.kiro/steering/script-safety.md). It is an `auto` steering file: Kiro loads it when you ask
for a script. Notice the rules: read-only by default, no secrets, arguments instead of hardcoded values, fail loudly, dry run for changes.

## 2. Level 1 – ask for the first script
Open a **new** chat and ask Kiro. Try this prompt, then compare with a vaguer one of your own:

> Write a Bash script `check-kitchen.sh` for Cat's Kitchen in `ap-southeast-1`, profile `workshop`.
> It must check: (1) ECS cluster `main-sandbox`, services `demo-frontend-service-sandbox` and `demo-backend-service-sandbox`:
> running tasks vs desired tasks; (2) Aurora cluster `demo-app-db-cluster-sandbox`: status.
> Print one line per check as OK / WARN / FAIL. Exit with code 1 if any check is FAIL.
> Read-only AWS calls only. Do not run it; show me the script and list every aws command it uses.

Why this prompt works: it names the **resources**, the **region and profile**, the **output you want**, the **exit code**, and a **safety limit**.

### Review it before you run it (this is the point of the lab)
Go through this checklist with the script Kiro gave you:

- [ ] Every `aws` command is `describe-*`, `list-*` or `get-*`. Nothing like `update-service`, `stop-db-cluster`, `delete-*`
- [ ] No access key, secret or password is in the file
- [ ] The profile and region are not buried in the code. You can change them with an argument
- [ ] It prints OK / WARN / FAIL and returns a non-zero exit code on FAIL
- [ ] You can explain in one sentence what each check does

If anything fails, tell Kiro exactly what is wrong and ask it to fix it. Then run it:

```bash
chmod +x check-kitchen.sh
./check-kitchen.sh
echo "exit code: $?"
```

Save the script **outside** the `.kiro/` folder (for example `./my-scripts/check-kitchen.sh`).

## 3. Level 2 – add more checks
Ask Kiro to extend your script. Pick at least two:

- ALB `main-alb-sandbox`: are all targets healthy?
- Call the app's `/api/health` with `curl` and check for HTTP 200
- Count the ALB `HTTPCode_Target_5XX_Count` in the last 15 minutes (CloudWatch metric)
- Make the profile, region and time window arguments (`--profile`, `--region`, `--minutes`)

Run it again. Then **break something on purpose** (safely): run it with a wrong profile name, or with a service name that does not exist.
A good script says clearly what failed. A bad one prints nothing or crashes with a long error.

> Outside class hours the database is stopped, so the Aurora check should say `stopped`. That should be a WARN, not a FAIL.

## 4. Level 3 – make it yours
Add a check that matters for **your** team's work, or change how it reports. Ideas:

- A one-line summary at the end: `Result: 0 FAIL, 1 WARN`
- Write the result as JSON for another tool
- Check one more thing: ECS task stopped reasons, or the latest deployment status
- Ask Kiro to rewrite the script in Python (`boto3`) and compare the two. Which is easier for you to read?

You can use this script as the starting point for your **Session 4** agent.

## 5. Compare with the instructors' version (only after you tried)
Instructors' reference script: [`reference/check-kitchen.sh`](reference/check-kitchen.sh). It is **not** the one right answer.
Compare:

- Which checks did Kiro include that the reference does not (and the other way round)?
- Did Kiro use any command that changes something? If so, how did you catch it?
- Which version is easier to read and to change?

## Good prompts for scripts
- Name the **resource**, **region**, **profile** and **expected output**
- Say what it must **not** do ("read-only", "do not run it")
- Ask Kiro to **list every external command** the script calls
- Ask for an **exit code** and **clear error messages**, so the script can run in cron or CI later

## Limits to remember
- Kiro can write a script that looks right and does the wrong thing. **You** are responsible for what you run.
- A read-only script is safe because your IAM role is read-only. Real limits come from IAM, not from the script.
- Never paste real secrets or customer data into a prompt or a script.

## Checkpoint
- [ ] You reviewed the script with the checklist before running it
- [ ] The script runs, prints OK / WARN / FAIL, and returns a non-zero exit code on a failure
- [ ] You caused one failure on purpose and the script reported it clearly
- [ ] You can name one risky command you would refuse to approve

## Troubleshooting
| Symptom | Likely cause |
|---|---|
| `Your session has expired` | Run `aws login --profile workshop` again |
| `AccessDenied` on a `describe-*` call | The IAM user is missing a read-only policy. Tell an instructor |
| `command not found: aws` or `jq` | Install it: `brew install awscli jq` |
| Kiro ignores the safety rules | Start a **new** chat. Steering is read when the chat starts |
| `date: illegal option` on Linux | The script was written for macOS `date -v`. Ask Kiro for a version that works on both |
