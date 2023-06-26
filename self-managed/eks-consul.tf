resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  chart      = "consul"
  namespace  = "consul"

  values = [
    templatefile("${path.module}/consul-helm/values.tpl", {
      datacenter       = var.datacenter
      consul_version   = substr(var.consul_version, 1, -1)
      api_gateway_version = var.api_gateway_version
    })
  ]

  depends_on = [module.eks.eks_managed_node_groups, kubernetes_namespace.consul, kustomization_resource.gateway_crds]
}

## Apply API Gateway CRDs

locals {
  # non-default context name to protect from using wrong kubeconfig
  kubeconfig_context = "_terraform-kustomization-${local.name}_"

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

provider "kustomization" {
  kubeconfig_raw = yamlencode(local.kubeconfig)
  context        = local.kubeconfig_context
}

data "kustomization_build" "gateway_crds" {
  path = "github.com/hashicorp/consul-api-gateway/config/crd?ref=v${var.api_gateway_version}"
}

resource "kustomization_resource" "gateway_crds" {
  for_each = data.kustomization_build.gateway_crds.ids
  manifest = data.kustomization_build.gateway_crds.manifests[each.value]
}

## Create API Gateway

data "kubectl_filename_list" "api_gw_manifests" {
  pattern = "${path.module}/api-gw/*.yaml"
}

resource "kubectl_manifest" "api_gw" {
  count     = length(data.kubectl_filename_list.api_gw_manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.api_gw_manifests.matches, count.index))

  depends_on = [helm_release.consul, kustomization_resource.gateway_crds]
}
