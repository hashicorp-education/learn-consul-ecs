################################################################################
# VPC
################################################################################

output "region" {
  value = var.vpc_region
}

output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

/*
output "hashicups_url" {
  value = "http://${module.aws_ecs_cluster.hashicups_url}"
}

output "next_steps" {
  value = "HashiCups Application will be ready in ~2 minutes. Use 'terraform output -raw consul_root_token' to retrieve the root token."
}
*/


################################################################################
# ECS Service(s)
################################################################################

/*
output "ecs_cluster_name" {
  value = data.aws_eks_cluster.cluster.name
}

output "hashicups_url" {
  value = aws_lb.ingress.dns_name
}
*/