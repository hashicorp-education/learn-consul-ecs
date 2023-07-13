# Payments API service
resource "aws_ecs_service" "payments_api" {
  name            = "payments_api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.hashicups_payments_api_task.arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}


# Product API service
resource "aws_ecs_service" "hashicups_product_api" {
  name            = "product_api"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.hashicups_product_api_task.arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}

# Product API DB service
resource "aws_ecs_service" "hashicups_product_db" {
  name            = "product_api_db"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.hashicups_product_api_db_task.arn
  desired_count   = 1
  network_configuration {
    subnets = module.vpc.private_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true
}


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
    logConfiguration = local.product_api_log_config
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


# Product API DB task defintion without Consul
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
    name             = "product-api-db"
    image            = "hashicorpdemoapp/product-api-db:v0.0.22"
    essential        = true
    logConfiguration = local.product_api_db_log_config
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

## AWS IAM roles and policies for ECS tasks

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${local.name}-execution"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name}-task"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  role       = "${aws_iam_role.ecs_task_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}