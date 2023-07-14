################################################################################
# VPC
################################################################################

output "region" {
  value = var.vpc_region
}

/*
output "vpc" {
  value = {
    vpc_id         = module.vpc.vpc_id
    vpc_cidr_block = module.vpc.vpc_cidr_block
  }
}
*/

################################################################################
# EKS Cluster
################################################################################

output "kubernetes_cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "kubernetes_cluster_id" {
  value = local.name
}

# I need the k8s node IP or DNS addresses
/*
output "kubernetes_all_cluster_resources" {
  value = data.aws_eks_cluster.cluster
}
*/


data "kubernetes_nodes" "node_data" {
  depends_on  = [helm_release.consul]
}

output "node_names" {
  value = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
}

output "consul_server_http_addr" {
  value = data.kubernetes_nodes.node_data.nodes.0.metadata.0.name
}

data "kubernetes_endpoints_v1" "consul-endpoints" {
  metadata {
    name = "consul-server"
    namespace = "consul"
  }
  depends_on  = [helm_release.consul, kubectl_manifest.hashicups]
}

output "consul-endpoints" {
  #value = [for endpoint in data.kubernetes_endpoints_v1.consul-endpoints.subset : endpoint.0.address.0.ip]
  #value = [data.kubernetes_endpoints_v1.consul-endpoints.subset.*.address.ip[0]]
  #value = [for endpoint in data.kubernetes_endpoints_v1.consul-endpoints.subset.*.address : endpoint.0.ip]
  #value = [data.kubernetes_endpoints_v1.consul-endpoints.subset[*].address[*].ip]
  #value = [for endpoint in data.kubernetes_endpoints_v1.consul-endpoints.subset[*].address[*].ip : endpoint.0.ip]
  value = [data.kubernetes_endpoints_v1.consul-endpoints.subset[*].address[*].ip]
}

/*
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
    name = "api-gateway"
  }
  depends_on  = [helm_release.consul, kubectl_manifest.hashicups]
}

output "consul-ui" {
  value = [data.kubernetes_service.consul-ui.status.0.load_balancer.0.ingress.0.hostname]
}
*/

/*
output "kubernetes_node_groups" {
  value = data.aws_eks_cluster.node_groups
}

output "kubernetes_node_groups_autoscaling" {
  value = data.aws_eks_cluster.node_groups_autoscaling
}
*/

# I need the Consul server CA cert 
# I need to enable HTTPS on Consul

/*
output "kubernetes_node_name" {
  value = data.aws_eks_node_group.resources
}
*/

/*
output "consul_server_address" {
  value = "https://${aws_lb.example_client_app.dns_name}:8502"
}
*/

################################################################################
# ECS Service(s)
################################################################################

output "ecs_cluster_name" {
  value = data.aws_ecs_cluster.ecs_cluster.cluster_name
}