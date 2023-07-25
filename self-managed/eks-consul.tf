//Consul namespace
resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

//Generated Kubernetes secrets
resource "kubernetes_secret" "consul_bootstrap_token" {
  metadata {
    name = "bootstrap-token"
    namespace = "consul"
  }

  data = {
    token = "${data.aws_secretsmanager_secret_version.bootstrap_token.secret_string}"
  }

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul
               ]

}

resource "kubernetes_secret" "consul_ca_key" {
  metadata {
    name = "ca-key"
    namespace = "consul"
  }

  data = {
    "tls.key" = "${data.aws_secretsmanager_secret_version.ca_key.secret_string}"
  }

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul
               ]

}

resource "kubernetes_secret" "consul_ca_cert" {
  metadata {
    name = "ca-cert"
    namespace = "consul"
  }

  data = {
    "tls.crt" = "${data.aws_secretsmanager_secret_version.ca_cert.secret_string}"
    
  }

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul
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
      datacenter       = var.datacenter
      consul_version   = substr(var.consul_version, 1, -1)
    })
  ]

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul, 
                aws_secretsmanager_secret.bootstrap_token, 
                aws_secretsmanager_secret.ca_cert, 
                aws_secretsmanager_secret.ca_key
                ]
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

## Create API Gateway

data "kubectl_filename_list" "api_gw_manifests" {
  pattern = "${path.module}/api-gw/*.yaml"
}

resource "kubectl_manifest" "api_gw" {
  count     = length(data.kubectl_filename_list.api_gw_manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.api_gw_manifests.matches, count.index))

  depends_on = [helm_release.consul, kubectl_manifest.hashicups]
}

## Get K8S node data

data "kubernetes_nodes" "node_data" {
  depends_on  = [helm_release.consul]
}