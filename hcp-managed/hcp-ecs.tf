# ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name               = local.name
}

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_provider" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


/*
# AWS ECS cluster, Consul ECS client, and HashiCups demo app in service mesh
module "aws_ecs_cluster" {
  source  = "hashicorp/hcp-consul/aws//modules/hcp-ecs-client"
  version = "~> 0.12.1"

  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  client_ca_file           = hcp_consul_cluster.main.consul_ca_file
  client_config_file       = hcp_consul_cluster.main.consul_config_file
  client_gossip_key        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
  client_retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_url               = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_version           = substr(hcp_consul_cluster.main.consul_version, 1, -1)
  datacenter               = hcp_consul_cluster.main.datacenter
  nat_public_ips           = module.vpc.nat_public_ips
  private_subnet_ids       = module.vpc.private_subnets
  public_subnet_ids        = module.vpc.public_subnets
  region                   = var.vpc_region
  root_token               = hcp_consul_cluster_root_token.token.secret_id
  security_group_id        = module.aws_hcp_consul.security_group_id
  vpc_id                   = module.vpc.vpc_id
}

*/