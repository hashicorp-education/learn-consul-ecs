resource "kubectl_manifest" "consul_namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: consul
YAML

  depends_on = [
    module.eks.eks_managed_node_groups
  ]
}

resource "kubectl_manifest" "consul_bootstrap_token" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: bootstrap-token
  namespace: consul
type: Opaque
data:
  token: ${base64encode(nonsensitive(data.aws_secretsmanager_secret_version.bootstrap_token.secret_string))}
YAML

  depends_on = [
    module.eks.eks_managed_node_groups,
    aws_secretsmanager_secret.bootstrap_token
  ]
}

resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  chart      = "consul"
  namespace  = "consul"

  values = [
    templatefile("${path.module}/consul-helm/values.tpl", {
      datacenter     = var.datacenter
      consul_version = var.consul_version
    })
  ]

  depends_on = [
    module.eks.eks_managed_node_groups,
    aws_secretsmanager_secret.bootstrap_token,
    module.vpc,
    kubectl_manifest.consul_namespace,
    kubectl_manifest.consul_bootstrap_token
  ]
}

## Create API Gateway
data "kubectl_filename_list" "api_gw_manifests" {
  pattern = "${path.module}/api-gw/*.yaml"
}

resource "kubectl_manifest" "api_gw" {
  count     = length(data.kubectl_filename_list.api_gw_manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.api_gw_manifests.matches, count.index))

  depends_on = [helm_release.consul, kubectl_manifest.hashicups]
}

locals {
  # non-default context name to protect from using wrong kubeconfig
  kubeconfig_context = "_terraform-kubectl-context-${local.name}_"

  kubeconfig = {
    apiVersion = "v1"
    clusters = [
      {
        name = local.kubeconfig_context
        cluster = {
          certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority.0.data
          server                     = data.aws_eks_cluster.cluster.endpoint
        }
      }
    ]
    users = [
      {
        name = local.kubeconfig_context
        user = {
          token = data.aws_eks_cluster_auth.cluster.token
        }
      }
    ]
    contexts = [
      {
        name = local.kubeconfig_context
        context = {
          cluster   = local.kubeconfig_context
          user      = local.kubeconfig_context
          namespace = "consul"
        }
      }
    ]
  }
}

## Get K8S node data for Consul ECS module usage
data "kubernetes_nodes" "node_data" {

  depends_on = [helm_release.consul]
}