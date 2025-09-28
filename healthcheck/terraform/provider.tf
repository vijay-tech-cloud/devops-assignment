data "aws_eks_cluster" "this" { name = module.eks.cluster.name }
data "aws_eks_cluster_auth" "this" {name = module.eks.cluster.name}
provider "aws" {
    region = var.region
    default_tags {
      tags = merge(var.tags, {"tf:stack"="eks-app", "owner"="var.owner"}
      )
    } 
}
provider "kubernetes" {
    host = data.aws_eks_cluster.this.endpoint
    token= data.aws_eks_cluster_auth.this.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
}
provider "helm" {
    kubernetes = {
      host = data.aws_eks_cluster.this.endpoint
      token= data.aws_eks_cluster_auth.this.token
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    }
  
}