# Setup Guide

Install and check these tools before Session 2. Please finish the setup before the class so you have more time for the labs.

## Required tools

### Install Homebrew first

Homebrew installs and updates the tools used in these labs.

- Install guide: [Homebrew](https://brew.sh/)

Install on macOS:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the instructions shown at the end of the installation. Close and open Terminal, then check Homebrew:

```bash
brew --version
```

### 1. Kiro IDE

Kiro is the main tool used in all four labs.

- Download: [Kiro downloads](https://kiro.dev/downloads/)

Install on macOS:

```bash
brew install --cask kiro
```

Open Kiro and sign in. Keep command approval turned on. Always read a command before you approve it.

### 2. AWS CLI v2

The AWS CLI connects your computer to the academy AWS sandbox.

- Install guide: [AWS CLI v2 installation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

Install on macOS:

```bash
brew install awscli
```

Check the installation:

```bash
aws --version
```

### 3. uv and uvx

The labs use `uvx` to download and run the AWS MCP servers on your computer.

- Install guide: [Installing uv](https://docs.astral.sh/uv/getting-started/installation/)

Install on macOS:

```bash
brew install uv
```

Check the installation:

```bash
uvx --version
```

If Kiro cannot find `uvx`, close and open Kiro again after installing `uv`.

### 4. Kiro CLI

Kiro CLI is used to run the command-line agent in Lab 04.

- Install guide: [Kiro installation](https://kiro.dev/docs/getting-started/installation/)

Install on macOS:

```bash
brew install --cask kiro-cli
```

Start Kiro CLI once and sign in:

```bash
kiro-cli
```

Check the installation:

```bash
kiro-cli --version
```

## Set up AWS access

Your instructor will give you access through **AWS IAM Identity Center (SSO)** with a **read-only** role in the academy AWS account.
You need three values from your instructor: the **SSO start URL**, the **SSO region**, and the **role name** (the account is selected for you).

**First time only.** Create the `workshop` profile:

```bash
aws configure sso --profile workshop
```

Answer the questions:

| Question | Answer |
|---|---|
| SSO session name | `academy` (any name is fine) |
| SSO start URL | the URL from your instructor |
| SSO region | the region from your instructor |
| SSO registration scopes | press Enter to accept the default |
| Account / role | pick the academy account and the read-only role |
| Default client Region | `ap-southeast-1` |
| Default output format | `json` |

Your browser opens to confirm the sign-in. Allow it, then return to the terminal.

**Every time you start** (the session expires after a few hours):

```bash
aws sso login --profile workshop
```

Your browser opens. Sign in, then return to the terminal. The temporary credentials are stored under `~/.aws`, outside this repository.
Never put an access key or secret in any file in this repository. When you see `ExpiredToken` or `The SSO session ... has expired`,
run `aws sso login --profile workshop` again.

Set the AWS profile and region for your current Terminal session:

```bash
export AWS_PROFILE=workshop
export AWS_DEFAULT_REGION=ap-southeast-1
```

Check your AWS identity:

```bash
aws sts get-caller-identity --profile workshop
```

The `Arn` in the result must be the academy read-only role (`arn:aws:sts::<account>:assumed-role/AWSReservedSSO_<role>_.../<you>`).
If it fails, stop and ask an instructor for help.

The academy sandbox is in the Singapore region:

```text
ap-southeast-1
```

## Final check

Run these commands before Session 2:

```bash
brew --version
aws --version
uvx --version
kiro-cli --version
aws sts get-caller-identity --profile workshop
```

Also check that:

- [ ] Kiro is installed and you can sign in.
- [ ] The five commands above finish without an error.
- [ ] Your AWS identity is the academy read-only SSO role.
- [ ] Your AWS region is `ap-southeast-1`.
- [ ] You can open the Cat's Kitchen URL shared by the instructors.
- [ ] Your network allows `uvx` to download packages. The first download may take a few minutes.

## Get help

If a check fails, send the full error message to an instructor before the session. Do not send passwords, access keys, secret keys, or session tokens.
