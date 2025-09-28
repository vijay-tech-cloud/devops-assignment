resource "helm_release" "secrets_store_csi" {
  name       = "secrets-store-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.6"
  set { 
    name="syncSecret.enabled"
    value="true" 
    }
}

resource "helm_release" "secrets_provider_aws" {
  name       = "secrets-provider-aws"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = "0.3.10"
}

data "aws_iam_policy_document" "app_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
         type = "Federated"
         identifiers = [module.eks.oidc_provider_arn] 
         }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:prod:tiny-app"]  # change ns/sa
    }
  }
}

resource "aws_iam_role" "app_irsa" {
  name               = "${var.cluster_name}-app-irsa"
  assume_role_policy = data.aws_iam_policy_document.app_assume.json
}

resource "aws_iam_policy" "app_secrets" {
  name = "${var.cluster_name}-app-secrets"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect="Allow", Action=["secretsmanager:GetSecretValue"], Resource="arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.me.account_id}:secret:trade/prod/*" },
      { Effect="Allow", Action=["ssm:GetParameter","ssm:GetParameters"], Resource="arn:aws:ssm:${var.region}:${data.aws_caller_identity.me.account_id}:parameter/trade/prod/*" }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_secrets_attach" {
  role       = aws_iam_role.app_irsa.name
  policy_arn = aws_iam_policy.app_secrets.arn
}

data "aws_caller_identity" "me" {}
