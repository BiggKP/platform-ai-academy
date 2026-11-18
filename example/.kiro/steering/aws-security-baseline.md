---
inclusion: manual
---
# AWS security baseline (review checklist)

Used by the `aws-security-reviewer` agent. Each area lists what to check and the reference to cite.
Severity: **High** = exposed or exploitable now. **Medium** = weak control. **Low** = hardening.

## 1. Identity and access (IAM)
- No wildcard `Action: "*"` or `Resource: "*"` on write actions. Roles follow least privilege.
- No long-lived access keys for workloads. Use IAM roles. MFA on human users and root. No root access keys.
- Trust policies limit who can assume a role (no `Principal: "*"` without conditions).
- Ref: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Ref: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/identity-and-access-management.html

## 2. Network
- Security groups: no `0.0.0.0/0` on SSH (22), RDP (3389), or database ports. Only the ALB is public.
- Databases and ECS tasks sit in private subnets. Use VPC endpoints for AWS services where practical.
- Ref: https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html
- Ref: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/infrastructure-protection.html

## 3. Data protection
- S3: Block Public Access on, default encryption on, versioning for important data, TLS-only bucket policy.
- RDS/Aurora, EBS, DynamoDB, SQS, SNS: encryption at rest (prefer customer managed KMS key for sensitive data). TLS in transit.
- Databases not publicly accessible. Backups and retention configured.
- Ref: https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- Ref: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/data-protection.html

## 4. Secrets
- No secrets in code, task definition plain-text env vars, or logs. Use Secrets Manager or SSM Parameter Store (SecureString).
- Rotation enabled where supported.
- Ref: https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html

## 5. Logging, detection, audit
- CloudTrail enabled in all regions with log file validation. Logs stored in a protected bucket.
- CloudWatch log groups have retention set. VPC Flow Logs and ALB access logs on for production.
- GuardDuty, Security Hub, and AWS Config enabled where in scope.
- Ref: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/best-practices-security.html
- Ref: https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/detection.html

## 6. Compute and edge (ECS, ALB)
- ECS task role and execution role are separate and minimal. Containers do not run privileged or as root where avoidable.
- ALB listeners use HTTPS with a current TLS policy. HTTP redirects to HTTPS. Consider WAF on public endpoints.
- Ref: https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/security.html
- Ref: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/Welcome.html

## Report format
For each finding give: **Severity**, **Resource** (ARN or id), **Evidence** (the setting you read),
**Why it matters**, **Recommended fix** (for a human to apply), **Reference** (URL from this file or AWS docs).
End with a list of areas you could not check (no permission or no data). Do not claim "secure" for those.
