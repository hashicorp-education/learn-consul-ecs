terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.65.0"
    }
    consul = {
      source = "hashicorp/consul"
      version = ">= 2.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2"
    }
  }

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }
}

provider "aws" {
  region = var.vpc_region
}

provider "consul" {
  address    = hcp_consul_cluster.main.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.main.datacenter
  token      = hcp_consul_cluster_root_token.token.secret_id
}