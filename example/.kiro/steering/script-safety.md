---
name: script-safety
description: Rules for writing or changing Bash, Python or PowerShell scripts that call AWS. Use when the user asks Kiro to write, fix, review or explain an automation script.
inclusion: auto
---

# Safe scripting rules

Follow these every time you write or edit a script.

1. **Read-only by default.** Use only `describe-*`, `list-*` and `get-*` AWS calls unless the user explicitly asks for a change.
   Never use `create`, `update`, `delete`, `put`, `stop`, `terminate`, `modify`, `run`, `rm -rf`, or `kubectl apply`/`delete`.
2. **No secrets in the file.** Never write an access key, secret, token or password into a script. Use the AWS profile name
   (`--profile`) and let the user pass it as an argument. Default profile: `workshop`, default region: `ap-southeast-1`.
3. **Take inputs as arguments** (profile, region, time window, names), with safe defaults. Do not hardcode account IDs.
4. **Fail loudly.** Bash: start with `set -uo pipefail`, check every command that can fail, print a clear message, and return a
   non-zero exit code when a check fails. Python: raise or `sys.exit(1)`; do not swallow exceptions.
5. **Dry run for anything that changes state.** If a script can change something, it must default to printing what it would do
   and need an explicit `--apply` flag.
6. **Short, readable output.** One line per check with a clear status (OK / WARN / FAIL) and the value that proves it.
7. **Explain before running.** Before the user runs a script, list every external command it calls and say whether each is read-only.
8. **Do not run it for the user** unless they ask. Show the command first and wait for approval.
