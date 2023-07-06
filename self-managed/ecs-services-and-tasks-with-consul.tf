# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


module "acl-controller" {
  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "0.6.0"

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }

  name_prefix               = var.name
  ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
  region                    = var.vpc_region
  subnets                   = module.vpc.private_subnets
  launch_type               = "FARGATE"

  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn
  #consul_server_ca_cert_arn         = aws_secretsmanager_secret.server_cert.arn
  #consul_server_ca_cert_arn         = aws_secretsmanager_secret.ca_cert.arn
  #consul_server_http_addr           = "10.0.4.254:8500"
  #consul_server_http_addr           = "https://${aws_instance.consul.private_ip}:8501"
  #consul_server_http_addr           = "http://10.0.4.114:8500"
  #consul_server_http_addr           = "http://ip-10-0-4-57.us-west-2.compute.internal:32255"
  consul_server_http_addr           = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"

  depends_on = [ aws_secretsmanager_secret.bootstrap_token, aws_secretsmanager_secret.ca_cert ]
}

/*
data "kubernetes_service" "consul_server" {
  metadata {
    name = "consul-server"
  }

    records = [data.kubernetes_service.consul_server.status.0.load_balancer.0.ingress.0.hostname]
}
*/

module "payment-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "payment-api"
  container_definitions = [
    {
      name      = "payment-api"
      image     = "hashicorpdemoapp/payments:v0.0.16"
      essential = true
      portMappings = [
        {
          containerPort = local.payment_api_port
          protocol      = "tcp"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.vpc_region
          awslogs-stream-prefix = "payment-api"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "payment-api"
    }
  }

  port = local.payment_api_port

  #retry_join        = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
  retry_join = ["${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32301"]
  #retry_join        = ["10.0.4.192"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn

  acls                      = true
  #consul_http_addr          = "https://10.0.4.242:8501"
  #consul_http_addr          = "http://10.0.4.254:8500"
  consul_http_addr           = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"


}

resource "aws_ecs_service" "payment-api" {
  name            = "payment-api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.payment-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    #security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "product-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "product-api"
  #task_role      = aws_iam_role.product-api-task-role
  #execution_role = aws_iam_role.product-api-execution-role
  container_definitions = [
    {
      name      = "product-api"
      image     = "hashicorpdemoapp/product-api:v0.0.20"
      essential = true
      portMappings = [
        {
          containerPort = local.product_api_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_CONNECTION"
          value = "host=localhost port=${local.product_db_port} user=postgres password=password dbname=products sslmode=disable"
        },
        {
          name  = "BIND_ADDRESS"
          value = "localhost:${local.product_api_port}"
        },
      ]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.vpc_region
          awslogs-stream-prefix = "product-api"
        }
      }
    }
  ]

  upstreams = [
    {
      destinationName = "product-db"
      localBindPort   = local.product_db_port
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "product-api"
    }
  }

  port = local.product_api_port

  #retry_join        = [for node in data.kubernetes_nodes.node_data.nodes : node.metadata.0.name]
  retry_join        = ["${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32301"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn

  acls                           = true
  #consul_http_addr          = "https://10.0.4.242:8501"
  consul_http_addr           = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"


}

resource "aws_ecs_service" "product-api" {
  name            = "product-api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.product-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    #security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

module "product-db" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family         = "product-db"
  #task_role      = aws_iam_role.product-db-task-role
  #execution_role = aws_iam_role.product-db-execution-role
  container_definitions = [
    {
      name      = "product-db"
      image     = "hashicorpdemoapp/product-api-db:v0.0.20"
      essential = true
      portMappings = [
        {
          containerPort = local.product_db_port
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
        },
      ]
      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log_group.name
          awslogs-region        = var.vpc_region
          awslogs-stream-prefix = "product-db"
        }
      }
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "product-db"
    }
  }

  port = local.product_db_port

  #retry_join        = [data.kubernetes_nodes.node_data.nodes.0.metadata.0.name]
  retry_join        = ["10.0.4.215:8301"]
  consul_datacenter = var.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${var.consul_version}"

  #tls                       = true
  #consul_server_ca_cert_arn = aws_secretsmanager_secret.server_cert.arn
  #consul_https_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn

  acls                           = true
  #consul_http_addr          = "https://10.0.4.242:8501"
  #consul_http_addr          = "http://10.0.4.254:8500"
  consul_http_addr           = "http://${data.kubernetes_nodes.node_data.nodes.0.metadata.0.name}:32500"
}

resource "aws_ecs_service" "product-db" {
  name            = "product-db"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.product-db.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    #security_groups = [var.security_group_id]
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

locals {
  frontend_port    = 3000
  public_api_port  = 7070
  payment_api_port = 8080
  product_api_port = 9090
  product_db_port  = 5432
}