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


################################################################################
# ECS Service(s)
################################################################################

output "ecs_cluster_name" {
  value = data.aws_ecs_cluster.ecs_cluster.cluster_name
}

output "hashicups_url" {
  value = aws_lb.ingress.dns_name
}
