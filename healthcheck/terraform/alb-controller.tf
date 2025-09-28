resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.2"

  set { 
    name = "clusterName"
    value = module.eks.cluster_name 
    }
  set { 
    name = "region"      
    value = var.region 
    }
  set { 
    name = "vpcId"
    value = local.vpc_id_out
     }

  set { 
    name = "serviceAccount.create"
    value = "true"
     }
  set { 
    name = "serviceAccount.name"
    value = "aws-load-balancer-controller"
     }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.alb_irsa.iam_role_arn
  }

  depends_on = [module.alb_irsa, module.eks]
}
