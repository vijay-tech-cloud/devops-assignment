# Cost Estimates & Cost Controls (us-east-1)

> **Scope:** EKS + ALB + NAT + EC2 workers, optional ElastiCache (Redis) and DynamoDB.
> **Assumptions:** 730 hours/month, very light traffic, single prod cluster, private subnets, 1 NAT Gateway, 1 ALB, small Redis, DynamoDB on‑demand, low logs/metrics. These are **ballpark** figures—verify in your account.

## Baseline Monthly Estimate

| Item | Monthly (USD) |
|---|---:|
| EKS control plane ($0.10/hr) | $73.00 |
| EC2 workers (2 × t3.medium) | $60.74 |
| NAT Gateway hourly (1 × $0.045/hr) | $32.85 |
| ALB hourly ($0.0225/hr) | $16.43 |
| ALB usage (≈1 LCU/hr @ $0.008) | $5.84 |
| ElastiCache (cache.t4g.micro) | $11.68 |
| DynamoDB on‑demand (100k writes + 100k reads) | $0.15 |
| CloudWatch Logs ingestion (1 GB) | $0.50 |
| CloudWatch custom metrics (12) | $3.60 |
| ECR storage (1 GB) | $0.10 |
| NAT data processing (5 GB @ $0.045/GB) | $0.23 |

**Subtotal:** **$205.11 / month** (excludes internet egress, cross‑AZ transfer, EBS, extra LCUs, etc).

## Variant: Graviton Workers (same everything else)
Replace t3.medium with **t4g.small** workers.

| Item | Monthly (USD) |
|---|---:|
| EKS control plane | $73.00 |
| EC2 workers (2 × t4g.small) | $24.53 |
| NAT Gateway hourly | $32.85 |
| ALB hourly | $16.43 |
| ALB usage (≈1 LCU/hr) | $5.84 |
| ElastiCache (cache.t4g.micro) | $11.68 |
| DynamoDB on‑demand (same) | $0.15 |
| CloudWatch Logs (1 GB) | $0.50 |
| CloudWatch custom metrics (12) | $3.60 |
| ECR storage (1 GB) | $0.10 |
| NAT data processing (5 GB) | $0.23 |

**Subtotal:** **$168.90 / month**  
**Savings vs baseline (workers only):** **-$36.21 / month**

> Note: EKS control plane jumps to **$0.60/hr** if your cluster is on a Kubernetes version in **extended support** (keep versions current).

---

## Where these numbers come from
- **EKS control plane**: $0.10/hr standard support; $0.60/hr extended support.  
- **NAT Gateway**: $0.045/hr + $0.045/GB data processing.  
- **ALB**: $0.0225 per ALB‑hour + $0.008 per LCU‑hour.  
- **EC2**: t3.medium ≈ $0.0416/hr; t4g.small ≈ $0.0168/hr (Linux, us‑east‑1).  
- **ElastiCache**: cache.t4g.micro ≈ $0.016/hr.  
- **DynamoDB on‑demand**: writes ~$1.25 / million WRU; reads ~$0.25 / million RRU.  
- **CloudWatch Logs**: ~$0.50/GB ingested.  
- **ECR**: ~$0.10/GB‑month storage; pulls within the same region are $0.00/GB.

(See the README answer for source links.)

---

## Cost Controls You Can Demonstrate

1. **Graviton everywhere** (EKS workers, ElastiCache) – lower $/hr; update node AMI to ARM.  
2. **Spot for non‑prod** – create a Spot nodegroup for staging/batch; keep a small On‑Demand buffer.  
3. **Scale‑to‑zero for non‑prod** – `terraform destroy` staging nightly/weekends; recreate per PR.  
4. **NAT optimization** – add VPC endpoints (ECR, S3, CloudWatch Logs) to reduce per‑GB processing via NAT; evaluate NAT instance for very low traffic (ops tradeoff).  
5. **Right‑size & autoscale** – small nodes + HPA; avoid idle replicas.  
6. **Logs/metrics hygiene** – 7–14d retention, sample debug logs, avoid many custom metrics.  
7. **DynamoDB** – stay on **on‑demand** until steady traffic; enable PITR only if required.  
8. **ElastiCache** – start at `cache.t4g.micro`; scale up when eviction alarms fire.

---

## AWS Budgets (50/80/100%)

Add this Terraform (edit `var.alert_email` and tags) to enable budget alerts:

```hcl
variable "alert_email" { type = string }

resource "aws_budgets_budget" "monthly_cost" {
  name              = "monthly-cost"
  budget_type       = "COST"
  limit_amount      = "50"          # USD
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "FORECASTED"
    threshold                   = 50
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "FORECASTED"
    threshold                   = 80
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }

  notification {
    comparison_operator         = "GREATER_THAN"
    notification_type           = "ACTUAL"
    threshold                   = 100
    threshold_type              = "PERCENTAGE"
    subscriber_email_addresses  = [var.alert_email]
  }
}
```

---

## Infracost (optional, CI)

```bash
# one-time
brew install infracost         # or chocolatey/apt
export INFRACOST_API_KEY=...

cd infra
terraform init && terraform plan -out=tf.plan
infracost breakdown --path . --format table

# PR comment example
infracost diff --path . --compare-to-file ../baseline.json --format github-comment --out-file infracost.md
```

Add a minimal `infracost-usage.yml` to model usage-based items:

```yaml
version: 0.1
resource_usage:
  aws_nat_gateway.this:
    monthly_gb_processed: 5
  aws_lb.alb:
    monthly_lcu_hours: 730
  aws_cloudwatch_log_group.app:
    monthly_gb_ingested: 1
  aws_ecr_repository.app:
    monthly_gb_storage: 1
```

---

## Caveats
- Region matters. Prices change—always check your region’s pricing pages.
- NAT **data processing** and ALB **LCUs** vary with traffic; use CloudWatch to measure real values.
- EC2 **Unlimited** CPU credits can add cost if you run hot for long periods; use Standard mode or right-size.
