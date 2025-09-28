output "vpc_id"             { value = local.vpc_id_out }
output "public_subnet_ids"  { value = local.public_subnet_ids_out }
output "private_subnet_ids" { value = local.private_subnet_ids_out }

output "cluster_name"       { value = module.eks.cluster_name }
output "cluster_endpoint"   { value = module.eks.cluster_endpoint }
output "oidc_provider_arn"  { value = module.eks.oidc_provider_arn }
output "alb_controller_role_arn" { value = module.alb_irsa.iam_role_arn }
output "waf_arn"            { value = try(aws_wafv2_web_acl.this.arn, null) }
output "dynamodb_table"     { value = aws_dynamodb_table.trades.name }
output "waf_arn" {
  value = aws_wafv2_web_acl.this.arn
}