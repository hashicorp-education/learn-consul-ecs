################################################################################
# VPC
################################################################################

output "region" {
  value = var.vpc_region
}

################################################################################
# EKS Cluster
################################################################################

output "kubernetes_cluster_id" {
  value = local.name
}

/*
output "kubernetes_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

data "kubernetes_nodes" "node_data" {
  depends_on  = [helm_release.consul]
}

output "node_names" {
  value = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
}

output "consul_server_http_addr" {
  value = data.kubernetes_nodes.node_data.nodes.0.metadata.0.name
}

data "kubernetes_service" "api-gateway" {
  metadata {
    name = "api-gateway"
  }
  depends_on  = [helm_release.consul, kubectl_manifest.hashicups]
}

output "api_gateway" {
  value = [data.kubernetes_service.api-gateway.status.0.load_balancer.0.ingress.0.hostname]
}

data "kubernetes_service" "consul-ui" {
  metadata {
    name = "consul-ui"
    namespace = "consul"
  }
  depends_on  = [helm_release.consul, kubectl_manifest.hashicups]
}

output "consul-ui" {
  value = [data.kubernetes_service.consul-ui.status.0.load_balancer.0.ingress.0.hostname]
}

output "kubernetes_node_groups" {
  value = data.aws_eks_cluster.node_groups
}

output "kubernetes_node_groups_autoscaling" {
  value = data.aws_eks_cluster.node_groups_autoscaling
}
*/


################################################################################
# ECS Service(s)
################################################################################

output "ecs_cluster_name" {
  value = data.aws_ecs_cluster.ecs_cluster.cluster_name
}