# Kong Gateway Dataplane Blue/Green on EKS with NLB

This repository implements a **zero-downtime blue/green deployment** of Kong Gateway dataplanes in **Amazon EKS**, managed via **ArgoCD (Helm)** and fronted by an **AWS Network Load Balancer (NLB)**.

## 📂 Repository Structure

```
infra/
  terraform/                # Terraform to create NLB, Target Groups, Listener, SSM params
    main.tf
    variables.tf
    outputs.tf
    post_apply_update_repo.sh
    lambda/                 # Lambda for automated cutover
      swap_lambda.py
      requirements.txt
apps/
  kong-dp-blue/             # ArgoCD Application for Kong Blue
    Application.yaml
    values-blue.yaml
    kong-blue-svc.yaml
    tg-binding-blue.yaml
  kong-dp-green/            # ArgoCD Application for Kong Green
    Application.yaml
    values-green.yaml
    kong-green-svc.yaml
    tg-binding-green.yaml
scripts/
  local-run-tf-and-update.sh
```

## 🚀 Deployment Workflow

1. **Provision Infra with Terraform**
   ```bash
   cd infra/terraform
   terraform init
   terraform apply -auto-approve
   ```
   - Creates the NLB, blue/green Target Groups, and listener (initially pointing to blue).
   - Stores ARNs in SSM Parameters.
   - Runs `post_apply_update_repo.sh` to inject the TG ARNs into the `tg-binding-*.yaml` manifests and push changes to Git.

2. **ArgoCD Sync**
   - ArgoCD deploys both `kong-dp-blue` and `kong-dp-green` Helm apps.
   - `aws-load-balancer-controller` automatically registers Kong pods in the correct TG.
   - Pods only become Ready after passing NLB health checks (Pod Readiness Gate).

3. **Automated Cutover (Lambda)**
   - A scheduled AWS Lambda (`swap_lambda.py`) polls the green Target Group health.
   - Once the configured number of healthy pods is reached for N polls, it atomically **swaps the NLB listener** from blue → green.
   - Ensures zero downtime traffic cutover.

4. **Post-Cutover**
   - Blue deployment can remain as fallback or be removed via ArgoCD (`kubectl delete app kong-dp-blue -n argocd`).

## 🛠 Requirements

- EKS cluster with ArgoCD installed
- [aws-load-balancer-controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/) installed with IRSA
- Terraform >= 1.3
- AWS CLI & kubectl configured
- GitOps repo accessible (ArgoCD watches it)

## 🔑 Key Components

- **Terraform**: Creates the NLB, TGs, and listener; manages outputs.
- **ArgoCD Applications**: Deploy Kong dataplanes (blue/green) via Helm chart.
- **TargetGroupBinding**: Attaches EKS Services to NLB TGs.
- **Lambda**: Automates listener swap based on TG health checks.

## ⚙️ Configuration

- Update `infra/terraform/variables.tf` with your VPC ID, subnet IDs, region, and Git repo details.
- Kong-specific values (control plane URL, TLS, etc.) go into `apps/kong-dp-blue/values-blue.yaml` and `apps/kong-dp-green/values-green.yaml`.

## 📋 Deployment Steps (CI/CD)

Typical GitOps pipeline:
1. Run Terraform → outputs TG ARNs → updates manifests in Git → ArgoCD syncs.
2. ArgoCD deploys green alongside blue.
3. Lambda detects healthy green TG → swaps listener automatically.
4. Blue can be pruned after confirmation.

## 🔒 Security Notes

- Lambda requires IAM permissions: `elbv2:DescribeTargetHealth`, `elbv2:ModifyListener`, `elbv2:DescribeListeners`, `ssm:GetParameter`.
- aws-load-balancer-controller must run with correct IAM role via IRSA.
- Git push in `post_apply_update_repo.sh` must be secured (bot user or deploy key).

## ✅ Benefits

- True **zero-downtime deployments** of Kong Gateway dataplane on EKS
- **Blue/Green strategy** with rollback safety
- **NLB only** (no ALB), aligned with strict infra requirements
- **Automated cutover** via Lambda — no manual AWS CLI calls

---

🔜 Next Steps:
- Extend Terraform to deploy the Lambda, IAM role, and EventBridge schedule for full infra-as-code automation.
- Tune `EXPECTED_HEALTHY` and `STABLE_COUNT` env vars in Lambda to match your Kong replica count and tolerance.

