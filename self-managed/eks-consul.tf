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

resource "kubernetes_secret" "consul_server_cert" {
  metadata {
    name = "server-cert"
    namespace = "consul"
  }

  data = {
    "tls.crt" = "${data.aws_secretsmanager_secret_version.server_cert.secret_string}"
    "tls.key" = "${data.aws_secretsmanager_secret_version.server_key.secret_string}"
  }

  type = "kubernetes.io/tls"

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
      api_gateway_version = var.api_gateway_version

    })
  ]

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul, 
                aws_secretsmanager_secret.bootstrap_token, 
                aws_secretsmanager_secret.ca_cert, 
                aws_secretsmanager_secret.ca_key,
                aws_secretsmanager_secret.server_cert
                ]
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

/* no longer need to install CRDs in Consul 1.16? 
still looks like we do though..
*/
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

  depends_on = [helm_release.consul, kubectl_manifest.hashicups]
}
