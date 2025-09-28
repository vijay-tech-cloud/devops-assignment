resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = "3.12.2"
}

data "aws_iam_policy_document" "ca_assume" {
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
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.ca_assume.json
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${var.cluster_name}-cluster-autoscaler"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect="Allow", Action=["autoscaling:Describe*","ec2:Describe*","eks:DescribeNodegroup"], Resource="*" },
      { Effect="Allow", Action=[
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Resource="*",
        Condition={ "StringEquals": { "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}" : "owned" } }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ca_attach" {
  role       = aws_iam_role.cluster_autoscaler.name
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.35.0" # for k8s 1.30

  set { 
    name = "autoDiscovery.clusterName"
    value = module.eks.cluster_name 
    }
  set { 
    name = "awsRegion"
    value = var.region 
    }
  set { 
    name = "rbac.serviceAccount.create"
    value = "true" 
    }
  set { 
    name = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
     }
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }

  depends_on = [module.eks]
}
