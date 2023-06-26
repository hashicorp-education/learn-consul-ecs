# Payments API service
resource "aws_ecs_service" "payment_api" {
  name            = "payment_api"
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
resource "aws_ecs_service" "hashicups_product_api_service" {
  name            = "${var.name}-hashicups_product_api_service"
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
resource "aws_ecs_service" "hashicups_product_api_db_service" {
  name            = "${var.name}-hashicups_product_api_db_service"
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