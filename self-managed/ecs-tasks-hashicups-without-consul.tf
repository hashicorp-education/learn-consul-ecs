resource "aws_ecs_task_definition" "hashicups_payments_api_task" {
  family                   = "payments_api"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "payments_api"
      image     = "hashicorpdemoapp/payments:v0.0.16"
      essential = true
      logConfiguration = local.payments_api_log_config

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      mountPoints = []
      volumesFrom = []
    }
  ])
}

# Product API task defintion without Consul
resource "aws_ecs_task_definition" "hashicups_product_api_task" {
  family                   = "${var.name}-hashicups_product_api_task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
    name             = "product-api"
    image            = "hashicorpdemoapp/product-api:v0.0.22"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "product-api"
      },
      {
        name  = "DB_CONNECTION"
        value = "host=localhost port=5432 user=postgres password=password dbname=products sslmode=disable"
      },
      {
        name  = "BIND_ADDRESS"
        value = "localhost:9090"
      },
      {
        name  = "METRICS_ADDRESS"
        value = "localhost:9103"
      }
    ]
    portMappings = [
      {
        containerPort = 9090
        hostPort      = 9090
        protocol      = "tcp"
      },
      {
        containerPort = 9103
        hostPort      = 9103
        protocol      = "tcp"
      }
    ]
    memory      = 512
    mountPoints = [
    ]
    volumesFrom = []
    }
  ])
}


# Public API DB task defintion without Consul
resource "aws_ecs_task_definition" "hashicups_product_api_db_task" {
  family                   = "${var.name}-hashicups_product_api_db_task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
    name             = "public-api-db"
    image            = "hashicorpdemoapp/product-api-db:v0.0.22"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "product-api-db"
      },
      {
        name  = "POSTGRES_DB"
        value = ":products"
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
    portMappings = [
      {
        containerPort = 5432
        hostPort      = 5432
        protocol      = "tcp"
      }
    ]
    memory      = 512
    mountPoints = [
      {
        sourceVolume = "pgdata",
        containerPath = "/var/lib/postgresql/data"
      }
    ]
    volumesFrom = []
    }
  ])
  volume {
    name      = "pgdata"
  }
}


resource "aws_cloudwatch_log_group" "log_group" {
  name = var.name
}

locals {
  example_server_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "server_app"
    }
  }

  example_client_app_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "client_app"
    }
  }

  payments_api_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "payments"
    }
  }

}