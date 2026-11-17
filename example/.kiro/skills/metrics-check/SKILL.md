---
name: metrics-check
description: Checks CloudWatch metrics for Cat's Kitchen ECS (CPU, memory), the ALB (5xx, latency, unhealthy hosts) and the Aurora database (CPU, connections, memory). Use when the user asks about CPU, memory, load, saturation, capacity, ALB health, database health, or whether a resource is overloaded during an incident.
---

# Metrics check (ECS, ALB, Aurora)

Region: `ap-southeast-1`. Read-only: only read metrics and describe resources, never change anything.

## 1. Scope first
Ask for the time window if not given. Default: the last 30 minutes. Use a period of 60 seconds.
Keep the window narrow: wide windows are slow and mix in older incidents.

## 2. Find the real resource names
Expected names in the sandbox (use them as a hint, but confirm they exist before querying):

| Resource | Name |
|---|---|
| ECS cluster | `main-sandbox` |
| ECS services | `demo-frontend-service-sandbox`, `demo-backend-service-sandbox` |
| ALB | `main-alb-sandbox` |
| Aurora cluster (provisioned, not Serverless) | `demo-app-db-cluster-sandbox` |

Do not guess dimension values. Look them up with the `aws-api` tool (read-only calls):

| Need | Call |
|---|---|
| ECS cluster | `ecs list-clusters` |
| ECS services | `ecs list-services --cluster <cluster>`  |
| ALB | `elbv2 describe-load-balancers`. The CloudWatch dimension `LoadBalancer` is the part of the ARN after `loadbalancer/`, e.g. `app/<name>/<id>` |
| Target groups | `elbv2 describe-target-groups`. The dimension `TargetGroup` is the part of the ARN after `:`, e.g. `targetgroup/<name>/<id>` |
| Aurora cluster | `rds describe-db-clusters` (use `DBClusterIdentifier`) |

## 3. Metrics to read (CloudWatch tool, statistic in brackets)

| Area | Namespace | Dimensions | Metrics |
|---|---|---|---|
| ECS | `AWS/ECS` | `ClusterName`, `ServiceName` | `CPUUtilization` (Average, Maximum), `MemoryUtilization` (Average, Maximum) |
| ALB | `AWS/ApplicationELB` | `LoadBalancer` | `HTTPCode_ELB_5XX_Count` (Sum), `HTTPCode_Target_5XX_Count` (Sum), `TargetResponseTime` (Average, p95), `RequestCount` (Sum) |
| ALB targets | `AWS/ApplicationELB` | `LoadBalancer`, `TargetGroup` | `UnHealthyHostCount` (Maximum), `HealthyHostCount` (Minimum) |
| Aurora | `AWS/RDS` | `DBClusterIdentifier` | `CPUUtilization` (Average, Maximum), `DatabaseConnections` (Maximum), `FreeableMemory` (Minimum) |

Check ECS for both the frontend and the backend service, and compare them.

## 4. Read the result
- Report each metric as: min / average / max over the window, and the time of the peak.
- Compare with the time of the first error. A spike that starts **after** the errors is more likely a symptom than the cause.
- Rules of thumb, not proof: CPU or memory above 80% for several minutes is worth a closer look; `UnHealthyHostCount` above 0
  means the ALB sees a failing target; `DatabaseConnections` close to the maximum can explain timeouts.
- Flat or missing metrics are not always an incident. The database is stopped outside class hours (18:00 and midnight, Bangkok time),
  so Aurora metrics are empty then.
- Never state a cause from metrics alone. Pair it with a log line (see the `incident-procedure` steering).

## 5. Answer format
Give a short table (resource, metric, min / avg / max, peak time), then 2-3 sentences on what stands out and what to check next.
Show the namespace, dimensions and time range you queried so the user can repeat it in CloudWatch.
