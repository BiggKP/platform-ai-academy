# Session 2 Labs – Kiro for Log Analysis & Troubleshooting

Four short labs. Do them in order; each builds on the previous one.

| Lab | You will | Time |
|---|---|---|
| [01 – MCP](01-mcp/README.md) | Connect Kiro to CloudWatch, CloudTrail and the AWS API (read-only) | 20 min |
| [02 – Steering](02-steering/README.md) | Teach Kiro about Cat's Kitchen and how we investigate | 20 min |
| [03 – Skills](03-skills/README.md) | Give Kiro a reusable skill that it loads only when a task needs it | 20 min |
| [04 – Custom agent](04-custom-agent/README.md) | Bundle all three into an "incident investigator" and use it on a real incident | 30 min |

```
example/
├── .kiro/
│   ├── settings/mcp.json                 # Lab 01
│   ├── steering/*.md                     # Lab 02
│   ├── skills/*/SKILL.md                 # Lab 03
│   └── agents/incident-investigator.*    # Lab 04
├── 01-mcp/README.md
├── 02-steering/README.md
├── 03-skills/README.md
└── 04-custom-agent/README.md
```

**Open `example/` as your Kiro workspace folder** so the `.kiro/` files are picked up.

## Before you start
- Kiro installed and signed in
- `uv` installed (`uvx --version` works)
- AWS CLI profile `workshop` (read-only, given by your instructors), region `ap-southeast-1`
  - check: `aws sts get-caller-identity --profile workshop`

## Safety rules for all labs
- **Never put an access key or secret in any file.** Config files only name the profile.
- Keep Kiro's command approval **on**. Read every command before approving it.
- Credentials are read-only. If Kiro suggests a fix, you apply it, not Kiro.

> The `.kiro/` paths here follow Kiro's documented layout. Menu names can differ slightly between Kiro versions;
> if something does not match, tell an instructor.
