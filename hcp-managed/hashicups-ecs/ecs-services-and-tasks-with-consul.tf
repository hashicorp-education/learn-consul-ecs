# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module "controller" {
  source  = "hashicorp/consul-ecs/aws//modules/controller"
  version = "0.7.3"

  # Address of the Consul server
  consul_server_hosts = substr(hcp_consul_cluster.main.consul_private_endpoint_url, 8, -1)

  # Configures TLS for the mesh-task.
  tls               = true

  # The HCP Consul HTTP with TLS API port
  http_config = {
    port = 443
    https = true
  }

  # The HCP Consul gRPC with TLS API port
  grpc_config = {
    port = 8502
  }

  # The ARN of the AWS SecretsManager secret containing the token to be used by this controller. 
  # The token needs to have at least `acl:write`, `node:write` and `operator:write` privileges in Consul
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn  

  name_prefix               = local.name
  ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
  region                    = var.vpc_region
  subnets                   = module.vpc.private_subnets
  launch_type               = "FARGATE"
  log_configuration         = local.acl_controller_log_config

  depends_on = [aws_secretsmanager_secret.bootstrap_token, aws_ecs_cluster.ecs_cluster, hcp_consul_cluster.main, module.aws_hcp_consul]
}

module "payments" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "0.7.3"


  # The name this service will be registered as in Consul.
  consul_service_name = "payments"

  # The port that this application listens on.
  port                = 7070

  # Address of the Consul server
  consul_server_hosts = substr(hcp_consul_cluster.main.consul_private_endpoint_url, 8, -1)

  # Configures ACLs for the mesh-task.
  acls              = true

  # Configures TLS for the mesh-task.
  tls               = true

  # The HCP Consul HTTP with TLS API port
  http_config = {
    port = 443
    https = true
  }

  # The HCP Consul gRPC with TLS API port
  grpc_config = {
    port = 8502
  }

  family         = "${local.name}-payments"
  cpu            = 512
  memory         = 1024
  log_configuration = local.payments_log_config

  container_definitions = [
    {
      name      = "payments"
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

      logConfiguration = local.payments_log_config
    }
  ]

  depends_on = [aws_ecs_cluster.ecs_cluster, module.controller]
}

resource "aws_ecs_service" "payments" {
  name            = "payments-consul"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.payments.task_definition_arn
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
  version = "0.7.3"  

  # The name this service will be registered as in Consul.
  consul_service_name = "product-api"

  # The port that this application listens on.
  port                = 9090

  # Address of the Consul server
  consul_server_hosts = substr(hcp_consul_cluster.main.consul_private_endpoint_url, 8, -1)

  # Configures ACLs for the mesh-task.
  acls              = true

  # Configures TLS for the mesh-task.
  tls               = true

  # The HCP Consul HTTP with TLS API port
  http_config = {
    port = 443
    https = true
  }

  # The HCP Consul gRPC with TLS API port
  grpc_config = {
    port = 8502
  }

  # Upstream Consul services that this service will call.
  upstreams = [
    {
      destinationName = "product-db"
      localBindPort   = 5432
    }
  ]  

  family         = "${local.name}-product-api"
  cpu            = 512
  memory         = 1024
  log_configuration = local.product_api_log_config

  # The ECS container definition
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

  depends_on = [aws_ecs_cluster.ecs_cluster, module.controller]
}

resource "aws_ecs_service" "product-api" {
  name            = "product-api-consul"
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
  version = "0.7.3"

  # The name this service will be registered as in Consul.
  consul_service_name = "product-db"

  # The port that this application listens on.
  port                = 5432

  # Address of the Consul server
  consul_server_hosts = substr(hcp_consul_cluster.main.consul_private_endpoint_url, 8, -1)

  # Configures ACLs for the mesh-task.
  acls              = true

  # Configures TLS for the mesh-task.
  tls               = true

  # The HCP Consul HTTP with TLS API port
  http_config = {
    port = 443
    https = true
  }

  # The HCP Consul gRPC with TLS API port
  grpc_config = {
    port = 8502
  }

  family         = "${local.name}-product-db"
  cpu            = 512
  memory         = 1024
  log_configuration = local.product_api_db_log_config

  # The ECS container definition
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

  depends_on = [aws_ecs_cluster.ecs_cluster, module.controller]
}

resource "aws_ecs_service" "product-db" {
  name            = "product-db-consul"
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
