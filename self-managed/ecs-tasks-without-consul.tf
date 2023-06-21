# Example client app task defintion without Consul
resource "aws_ecs_task_definition" "example_client_app" {
  family                   = "${var.name}-example-client-app"
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
    name             = "example-client-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_client_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-client-app"
      },
      {
        name  = "UPSTREAM_URIS"
        value = "http://localhost:1234"
      }
    ]
    portMappings = [
      {
        containerPort = 9090
        hostPort      = 9090
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

# Example server app task defintion without Consul
resource "aws_ecs_task_definition" "example_server_app" {
  family                   = "${var.name}-example-server-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  #port                    = "9090"
  #log_configuration       = local.example_server_app_log_config
  
  container_definitions = jsonencode([
    {
    name             = "example-server-app"
    image            = "ghcr.io/lkysow/fake-service:v0.21.0"
    essential        = true
    logConfiguration = local.example_server_app_log_config
    environment = [
      {
        name  = "NAME"
        value = "${var.name}-example-server-app"
      }
    ]
    cpu         = 10
    memory      = 512
    }
  ])
}