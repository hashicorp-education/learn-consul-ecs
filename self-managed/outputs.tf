################################################################################
# VPC
################################################################################

output "region" {
  value = var.vpc_region
}

output "vpc" {
  value = {
    vpc_id         = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
  }
}

################################################################################
# EKS Cluster
################################################################################

/*
output "kubernetes_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "kubernetes_cluster_id" {
  value = local.name
}
*/

################################################################################
# ECS Service(s)
################################################################################

output "client_lb_address" {
  value = "http://${aws_lb.example_client_app.dns_name}:9090/ui"
}