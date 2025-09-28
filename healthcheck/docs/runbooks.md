# Runbooks


## Structure
- `app/` - Server.js, package.json, package-lock.json, Dockerfile, unittest/
- `terraform/` - alb-controller, alb-iam, autoscaler, cloudwatch, redis, dynamodb, secrets, vpc + sunnets, EKS 
- `deployments/` — Namespaces, blue+green Deployments, Service, HPA, PDB, Ingress, SecretProviderClass
- `jenkins/Jenkinsfile` — full pipeline (build→scan→ECR→TF→staging→tests→gate→prod blue/green→post-verify)
- `tests/newman/collection.json` — smoke/e2e
- `tests/load/k6.js` — quick load with thresholds
- `docs/slo.md`, `docs/runbooks.md`

## Quick start
1) Build & push image to ECR (first create repo if needed):
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
REPO=trade-api
IMAGE=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO:$(git rev-parse --short HEAD)
aws ecr describe-repositories --repository-names $REPO || aws ecr create-repository --repository-name $REPO
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker build -t $IMAGE ./healthcheck/app && docker push $IMAGE
```

# Trade API — USING Node.js

API's

- `GET /health` → `200 {"ok": true}`
- `POST /trade/place` → `200 {"status":"accepted","id":"<uuid>"}`

## Folder Structure
```
app/
─ unittest/
─ Dockerfile
─ package.json
─ package-lock.json
─ server.js
```

## Prerequisites
- Node.js **20+**
- npm
- Docker

## Validating the api
```bash
cd healthcheck/app
npm i 
or 
npm install          
npm start       
```
![alt text](image.png)

Command to Verify :
```bash
Invoke-RestMEthod -Uri http://127.0.0.1:8080/health
# {"ok":true}
![alt text](image-1.png)
Invoke-RestMethod -Uri http://localhost:8080/trade/place -Method POST -Headers @{"Content-Type"= "application/json"} -Body "{}"
# {"status":"accepted","id":"<uuid>"}
![alt text](image-2.png)
```


## Docker Commands
Build:
```bash
docker build -t trade-api:latest .
```
Run:
```bash
docker run --rm -p 8080:8080 -e PORT=8080 trade-api:latest
```
## Security &  Best Practises for production env
- Limit body size: `app.use(express.json({ limit: '100kb' }))`.
- Container: run as **non-root**, add a **HEALTHCHECK**, and keep image small (alpine).
- No secrets in code; use AWS Secrets Manager/SSM when infra is created or provisioned.


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
- `budgets.tf` - For Cost Calculation and Sending the Alert on (50/80/100% usgae)
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

## ALB 5xx spike
1) Inspect ALB target health & 5xx in CloudWatch.
2) Check pod restarts & logs.
3) If during cutover, rollback to previous color.

# Task 3 — Deployment Yaml file + Blue-green Deployment Strategy

# Kubernetes Blue/Green Manifests

- `namespace.yml` — staging & prod
- `blue-deployment.yml` & `templates with `${NAMESPACE}` and `${IMAGE_URI}`
- `green-deployment.yml` & `templates with `${NAMESPACE}` and `${IMAGE_URI}`
- `service.yml` — selects active track (blue initially)
- `hpa.yml` — CPU-based pod autoscaling for blue
- `pdb.yml` — minAvailable=1 for safe disruptions
- `ingress.yml` — ALB (HTTP); add WAF ARN when available
- `secrets.yml` — Secrets Store CSI example

# Commands (Locally)
- Kubectl apply -f deployments/namespace.yml
- Kubectl apply -f deployments/blue-deployment.yml (Replace namespace and imageuri)
- Kubectl apply -f deployments/green-deploymnet.yml (Replace namespace and imageuri)
- Kubectl apply -f deployments/service.yml
- Kubectl apply -f deployments/hpa.yml
- Kubectl apply -f deployments/pdb.yml
- Kubectl apply -f deployments/secrets.yml
- Kubectl apply -f deployments/ingress.yml (Uncomment the annotation for WAF with waf ARN)


## Rollback
`kubectl -n prod patch svc tiny -p '{"spec":{"selector":{"app":"tiny","track":"blue"}}}'`


# Task 4 — Jenkins whole end to end pipeline

# CI/CD with Jenkins (Multibranch)

Stages:
1. Checkout
2. Build & Unit Test
3. SAST & Secrets (gitleaks, trivy)
4. Docker build & SBOM (Syft) → ECR
5. Terraform plan/apply (per env)
6. Deploy to staging (K8s Manifests)
7. Smoke/E2E (Newman)
8. Quick load (k6): thresholds p95<300ms, errors<1%
9. Manual gate to prod
10. Blue/Green switch (Service selector)
11. Post-verify (smoke + k6)
12. Archive reports


## Jenkins notes
- Create three credentials: `aws-access-key-id`, `aws-secret-access-key`, `aws-region` (secret text).
- Jenkins agent needs Docker, AWS CLI, kubectl, Terraform.
- Point a Multibranch Pipeline job to your repo; Jenkinsfile lives under `jenkins/Jenkinsfile`.


## Deployment Strategy Selection:

## Blue/Green vs Canary
**Blue/Green** — simple, instant rollback; no gradual ramp; rely on pre-switch tests.  
**Canary** — safer ramp; more operational steps (ALB weights), longer deploys.


## Pipeline Notes
- once we ran the pipeline for both the env then we can comment the infra creation stage in the pipeline to avoid the issues or errors while running the pipeline
- Eg: If we run the pipeline without commenting the infra stage then it will start failing and start complaining that the resource with same name already exists.