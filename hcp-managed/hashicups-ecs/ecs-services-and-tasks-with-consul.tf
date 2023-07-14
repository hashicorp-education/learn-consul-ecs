# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module "acl-controller" {
  source  = "hashicorp/consul-ecs/aws//modules/acl-controller"
  version = "0.6.0"

  log_configuration = local.acl_controller_log_config

  name_prefix               = local.name
  ecs_cluster_arn           = aws_ecs_cluster.ecs_cluster.arn
  region                    = var.vpc_region
  subnets                   = module.vpc.private_subnets
  launch_type               = "FARGATE"

  consul_server_http_addr           = hcp_consul_cluster.main.consul_private_endpoint_url
  consul_bootstrap_token_secret_arn = aws_secretsmanager_secret.bootstrap_token.arn

  depends_on = [aws_secretsmanager_secret.bootstrap_token, aws_ecs_cluster.ecs_cluster, hcp_consul_cluster.main, module.aws_hcp_consul]
}

module "payment-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family            = "payment-api"
  cpu               = 512
  memory            = 1024
  log_configuration = local.payments_api_log_config
  port              = 7070
  
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

  retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_datacenter = hcp_consul_cluster.main.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${substr(hcp_consul_cluster.main.consul_version, 1, -1)}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                      = true
  consul_http_addr          = hcp_consul_cluster.main.consul_private_endpoint_url


  depends_on = [module.acl-controller]
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

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

module "product-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family            = "product-api"
  cpu               = 512
  memory            = 1024
  log_configuration = local.product_api_log_config
  port              = 9090

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

  retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_datacenter = hcp_consul_cluster.main.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${substr(hcp_consul_cluster.main.consul_version, 1, -1)}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                      = true
  consul_http_addr          = hcp_consul_cluster.main.consul_private_endpoint_url


  depends_on = [module.acl-controller]
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

  family            = "product-db"
  cpu               = 512
  memory            = 1024
  log_configuration = local.product_api_db_log_config
  port              = 5432

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

  retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_datacenter = hcp_consul_cluster.main.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${substr(hcp_consul_cluster.main.consul_version, 1, -1)}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                      = true
  consul_http_addr          = hcp_consul_cluster.main.consul_private_endpoint_url


  depends_on = [module.acl-controller]
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

module "frontend-nginx" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family            = "frontend-nginx"
  cpu               = 512
  memory            = 1024
  log_configuration = local.frontend_nginx_log_config
  port              = 80

  container_definitions = [
    {
      name      = "frontend-nginx"
      image     = "hashicorpdemoapp/frontend-nginx:v1.0.9"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NEXT_PUBLIC_PUBLIC_API_URL"
          value = "/"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = local.frontend_nginx_log_config
    }
  ]

  upstreams = [
    {
      destinationName = "public-api"
      localBindPort   = 8080
    }
  ]

  retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_datacenter = hcp_consul_cluster.main.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${substr(hcp_consul_cluster.main.consul_version, 1, -1)}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                      = true
  consul_http_addr          = hcp_consul_cluster.main.consul_private_endpoint_url


  depends_on = [module.acl-controller]

}

resource "aws_ecs_service" "frontend-nginx" {
  name            = "frontend-nginx"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.frontend-nginx.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow_all_into_ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend-nginx.arn
    container_name   = "frontend-nginx"
    container_port   = 80
  }

  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true

  depends_on = [aws_ecs_cluster.ecs_cluster]
}

module "public-api" {
  source  = "hashicorp/consul-ecs/aws//modules/mesh-task"
  version = "~> 0.6.0"

  family            = "public-api"
  cpu               = 512
  memory            = 1024
  log_configuration = local.public_api_log_config
  port              = 8080

  container_definitions = [
    {
      name      = "public-api"
      image     = "hashicorpdemoapp/public-api:v0.0.6"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "BIND_ADDRESS",
          value = ":8080"
        },
        {
          name  = "PRODUCT_API_URI"
          value = "http://localhost:9090"
        },
        {
          name  = "PAYMENT_API_URI"
          value = "http://localhost:7070"
        }
      ]

      cpu         = 0
      mountPoints = []
      volumesFrom = []

      logConfiguration = local.public_api_log_config
    }
  ]

  upstreams = [
    {
      destinationName = "product-api"
      localBindPort   = 9090
    },
    {
      destinationName = "payment-api"
      localBindPort   = 7070
    }
  ]

  retry_join        = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["retry_join"]
  consul_datacenter = hcp_consul_cluster.main.datacenter
  consul_image      = "public.ecr.aws/hashicorp/consul:${substr(hcp_consul_cluster.main.consul_version, 1, -1)}"

  tls                       = true
  consul_server_ca_cert_arn = aws_secretsmanager_secret.ca_cert.arn
  gossip_key_secret_arn     = aws_secretsmanager_secret.gossip_key.arn

  acls                      = true
  consul_http_addr          = hcp_consul_cluster.main.consul_private_endpoint_url


  depends_on = [module.acl-controller]
}

resource "aws_ecs_service" "public-api" {
  name            = "public-api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = module.public-api.task_definition_arn
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow_all_into_ecs.id]
  }

/*
  load_balancer {
    target_group_arn = aws_lb_target_group.public-api.arn
    container_name   = "public-api"
    container_port   = 8080
  }
*/

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
