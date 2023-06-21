
/*

# Public API task defintion without Consul
resource "aws_ecs_task_definition" "hashicups_public_api_task" {
  family                   = "${var.name}-hashicups_public_api_task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  #port                    = "9090"
  #log_configuration       = local.example_client_app_log_config

  container_definitions = jsonencode([
    {
    name             = "public-api"
    image            = "hashicorpdemoapp/public-api:v0.0.7"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "public-api"
      },
      {
        name  = "BIND_ADDRESS"
        value = ":8080"
      },
      {
        name  = "PRODUCT_API_URI"
        value = "http://localhost:9090"
      },
      {
        name  = "PAYMENT_API_URI"
        value = "http://localhost:1800"
      }     
    ]
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
        protocol      = "tcp"
      }
    ]
    cpu         = 10
    memory      = 512
    mountPoints = []
    volumesFrom = []
    }
  ])
}

*/


# Product API task defintion without Consul
resource "aws_ecs_task_definition" "hashicups_product_api_task" {
  family                   = "${var.name}-hashicups_product_api_task"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  #port                    = "9090"
  #log_configuration       = local.example_client_app_log_config

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
        name  = "CONFIG_FILE"
        value = "/config/conf.json"
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
    cpu         = 10
    memory      = 512
    command     = ["/bin/sh -c \"echo '{\"db_connection\": \"host=localhost port=5432 user=postgres password=password dbname=products sslmode=disable\", \"bind_address\": \":9090\", \"metrics_address\": \":9103\"}' >> /config/conf.json"]

    mountPoints = []
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
  #port                    = "9090"
  #log_configuration       = local.example_client_app_log_config

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
    cpu         = 10
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