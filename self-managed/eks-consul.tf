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

/*
data "kubernetes_service" "consul_server" {
  metadata {
    name = "consul-server"
  }
}

value = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

# Get Consul server URL and store as a Terraform variable/output
export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d)
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export CONSUL_HTTP_SSL_VERIFY=false



data "kubernetes_service" "consul_api_gateway" {
  metadata {
    name = "api-gateway"
  }
}
value = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

# Get Consul API Gateway URL and store as a Terraform variable/output
export CONSUL_APIGW_ADDR=http://$(kubectl get svc/api-gateway --namespace consul -o json | jq -r '.status.loadBalancer.ingress[0].hostname'):8080

*/


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

  depends_on = [helm_release.consul, kustomization_resource.gateway_crds, kubectl_manifest.hashicups]
}
