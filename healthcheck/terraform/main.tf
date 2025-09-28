data "aws_availability_zones" "available" {}
data "aws_eks_cluster" "this"       { name = module.eks.cluster_name }
data "aws_eks_cluster_auth" "this"  { name = module.eks.cluster_name }

module "vpc" {
  count   = var.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${var.cluster_name}-vpc"
  cidr = var.cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnet_ids
  private_subnets = var.private_subnet_ids

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }
}

locals {
  vpc_id_out             = var.create_vpc ? module.vpc[0].vpc_id          : var.vpc_id
  public_subnet_ids_out  = var.create_vpc ? module.vpc[0].public_subnets  : var.public_subnet_ids
  private_subnet_ids_out = var.create_vpc ? module.vpc[0].private_subnets : var.private_subnet_ids
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.17"

  cluster_name                    = var.cluster_name
  cluster_version                 = "1.30"
  vpc_id                          = local.vpc_id_out
  subnet_ids                      = local.private_subnet_ids_out     
  cluster_endpoint_public_access  = true
  enable_irsa                     = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]  
      ami_type       = var.ami_type
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
      subnet_ids     = local.private_subnet_ids_out
      capacity_type  = "ON_DEMAND"     # "SPOT" for staging
    }
  }

  tags = { "kubernetes.io/cluster/${var.cluster_name}" = "owned" }
}

