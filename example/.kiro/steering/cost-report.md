---
inclusion: manual
---
# AWS cost report format (executive)

Used by the `aws-cost-reviewer` agent. The views follow AWS Cost Explorer so readers can open the same view in the console and get the same numbers.

## Defaults (same as Cost Explorer)
- **Period:** the last full calendar month (for example 2026-10-01 to 2026-10-31). Cost Explorer end dates are exclusive, so query `End = first day of this month`. Call `get_today_date` first; never guess the date.
- **Comparison period:** the month before it.
- **Metric:** `UnblendedCost`. Say so in the report. If the account has Savings Plans or RIs, also show `AmortizedCost` and explain the difference in one line.
- **Charge types:** exclude `Credit`, `Refund` and `Tax` from service totals. Show them as separate lines under the total.
- **Currency:** USD, 2 decimals. Percentages to 1 decimal.

## Queries to run (keep calls few, each one costs USD 0.01)
1. Monthly total, both months: granularity `MONTHLY`.
2. Group by `SERVICE`, both months: granularity `MONTHLY`.
3. Daily trend for the report month: granularity `DAILY`, no grouping.
4. Group by `REGION` and by `LINKED_ACCOUNT` (only if there are several accounts) for the report month.
5. `get_cost_comparison_drivers` between the two months (top drivers).
6. `get_cost_forecast` for the current month.
7. Optional: group by tag (for example `Project` or `env`) if the user names one. Report the untagged share.

## Report structure (use exactly)

### 1. Executive summary
3 to 5 bullets, plain language, no AWS jargon:
total spend, change vs previous month (USD and %), the main reason for the change, forecast for this month, one recommended action.

### 2. Headline numbers
| Metric | Previous month | Report month | Change (USD) | Change (%) |
|---|---|---|---|---|
| Total cost | | | | |
| Credits / refunds / tax | | | | |
| Forecast (current month) | | | | |

### 3. Cost by service (Cost Explorer: Group by Service)
Top 10 services by report-month cost, then one line "Others".
| Service | Previous month | Report month | Change (USD) | Change (%) | Share of total |
|---|---|---|---|---|---|

### 4. Daily trend
List the days that are more than 20% above the daily average, with the cost and the service that drove it.
Add a mermaid `xychart-beta` line chart of daily cost.

### 5. Cost by region / account / tag
One small table each, only where the data has more than one value.

### 6. What drove the change
From `get_cost_comparison_drivers`: top drivers with USD impact and a one-line explanation each.

### 7. Optimization opportunities
Up to 5 items. For each: what, estimated monthly saving (mark it as an estimate and show the arithmetic), effort (Low/Medium/High), owner to decide.
Base items on the data (for example idle NAT Gateway, large CloudWatch Logs ingestion, gp2 volumes, on-demand compute with steady usage). Link the AWS reference:
- Cost Optimization Pillar: https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html
- Cost Explorer: https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html

### 8. Data notes
Period, metric, filters, charge types excluded, the time the data was pulled, and that the last 24 hours of cost data may still change.
List anything you could not query and why.
