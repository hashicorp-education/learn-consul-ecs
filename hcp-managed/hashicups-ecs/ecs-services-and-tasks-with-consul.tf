# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module "acl-controller" {
  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "0.6.0"

  log_configuration = local.acl_controller_log_config

  name_prefix               = var.name
  ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
  region                    = var.vpc_region
  subnets                   = module.vpc.private_subnets
  launch_type               = "FARGATE"

  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  #consul_server_ca_cert_arn         = aws_secretsmanager_secret.ca_cert.arn

  consul_server_http_addr           = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"

  depends_on = [ aws_secretsmanager_secret.bootstrap_token, aws_secretsmanager_secret.ca_cert, aws_ecs_cluster.ecs_cluster]
}

module "payment-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "payment-api"
  cpu            = 512
  memory         = 1024
  container_definitions = [
    {
      name      = "payment-api"
      image     = "hashicorpdemoapp/payments:v0.0.16"
      essential = true
      portMappings = [
        {
          containerPort = 7070
          protocol      = "tcp"
        }
      ]

      mountPoints = []
      volumesFrom = []

      logConfiguration = local.payments_api_log_config
    }
  ]

  # how does this log config differ from the one in the container definition
  log_configuration = local.payments_api_log_config

  port = 7070

  #retry_join        = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
  retry_join        = ["${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32301"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn  = aws_secretsmanager_secret.ca_cert.arn

  acls                      = true
  consul_http_addr          = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

resource "aws_ecs_service" "payment-api" {
  name            = "payment-api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.payment-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow_all_into_ecs.id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "product-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "product-api"
  cpu            = 512
  memory         = 1024
  container_definitions = [
    {
      name      = "product-api"
      image     = "hashicorpdemoapp/product-api:v0.0.20"
      essential = true
      portMappings = [
        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_CONNECTION"
          value = "host=localhost port=5432 user=postgres password=password dbname=products sslmode=disable"
        },
        {
          name  = "BIND_ADDRESS"
          value = "localhost:9090"
        }
      ]
      mountPoints = []
      volumesFrom = []

      logConfiguration = local.product_api_log_config
    }
  ]

  upstreams = [
    {
      destinationName = "product-db"
      localBindPort   = 5432
    }
  ]

  log_configuration = local.product_api_log_config

  port = 9090

  #retry_join        = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
  retry_join        = ["${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32301"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn  = aws_secretsmanager_secret.ca_cert.arn

  acls                      = true
  consul_http_addr          = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

resource "aws_ecs_service" "product-api" {
  name            = "product-api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.product-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow_all_into_ecs.id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

module "product-db" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "product-db"
  cpu            = 512
  memory         = 1024
  container_definitions = [
    {
      name      = "product-db"
      image     = "hashicorpdemoapp/product-api-db:v0.0.19"
      essential = true
      portMappings = [
        {
          containerPort = 5432
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "POSTGRES_DB"
          value = "products"
        },
        {
          name  = "POSTGRES_USER"
          value = "postgres"
        },
        {
          name  = "POSTGRES_PASSWORD"
          value = "password"
        }
      ]
      mountPoints = []
      volumesFrom = []

      logConfiguration = local.product_api_db_log_config
    }
  ]

  log_configuration = local.product_api_db_log_config

  port = 5432

  retry_join        = ["${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32301"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn  = aws_secretsmanager_secret.ca_cert.arn

  acls                      = true
  consul_http_addr          = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

resource "aws_ecs_service" "product-db" {
  name            = "product-db"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.product-db.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow_all_into_ecs.id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
  
  depends_on = [aws_ecs_cluster.ecs_cluster]
}

resource "aws_security_group" "allow_all_into_ecs" {
  name        = "allow_ingress_into_ecs"
  description = "Allow all inbound traffic into ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "all in from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

}