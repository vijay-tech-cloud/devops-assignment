# Task 2 — Infrastructure (Terraform): EKS + ALB Ingress

---

## Folder Structure (Terraform)
Place these files inside your `healthcheck/terraform/` :
- `versions.tf` – required providers
- `variables.tf` – inputs (region, vpc, subnets, sizes, tags)
- `providers.tf` – AWS + EKS + Kubernetes/Helm providers 
- `main.tf` - AWS EKS module
- `alb-iam.tf` – official ALB Controller IAM policy + IRSA role
- `alb-controller.tf` – Helm release for the controller
- `autoscale.tf` - Meterics Server + Autoscaling policy + Cluster Autoscaler
- `cloudwatch.tf` - Cloudwatch Meterics Alarms for 5xx + Latency p95
- `waf.tf` - Web ACL + AWS Common Rules
- `secrets.tf` - Helm CSI Store + Helm Secrets Provider
- `outputs.tf` – handy outputs
- `terraform.tfvars.example` – sample variables file
- `Flowdiagram(architecture).jpg` - High level Architecture flow 
---

## Prerequisites
- AWS account + CLI configured
- Existing **VPC** and **private subnets** in **≥2 AZs** (with **NAT** access)
- Terraform **1.6+**
- `kubectl`, `helm`
- IAM permissions to create EKS/IAM/Helm resources

---

## Configure variables
Make a `terraform.tfvars` based on the example:
```hcl
region = "us-east-1"

# If creating VPC in this stack:
create_vpc = true

# If using existing VPC instead:
# create_vpc = false
# vpc_id             = "vpc-xxxxxxxx"
# public_subnet_ids  = ["subnet-aaaa","subnet-bbbb"]
# private_subnet_ids = ["subnet-cccc","subnet-dddd"]

min_size     = 1
max_size     = 3
desired_size = 1
ami_type     = "AL2_x86_64"  # or "AL2_ARM_64" + t4g instances

create_redis = false

owner = "platform"
tags  = { project = "trade-minimal" }

```

---

## Plan & Apply
```bash
terraform init
terraform plan -out tf.plan
terraform apply -auto-approve tf.plan
```

---

## Verify the cluster & controller
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region <your-region>

kubectl -n kube-system get deploy aws-load-balancer-controller
```

If the deployment is not ready yet, wait 1–2 minutes.
---

## Best practices
- **IRSA**: least‑privileged IAM role for the controller (policy pulled from upstream and pinned).
- **Node types**: default is `t3.medium` with `AL2_x86_64`. For Graviton, switch to `t4g.small` + `ami-image` (ensure your app images support `linux/arm64`).
- **Capacity type**: use `SPOT` for staging; `ON_DEMAND` for prod.
- **Access**: `enable_cluster_creator_admin_permissions = true` is set for convenience; lock down later.
- **Tagging**: keep `owner`, `project`, and `tf:stack` for cost allocation.

---
## Cleanup
```bash
terraform destroy -auto-approve
```