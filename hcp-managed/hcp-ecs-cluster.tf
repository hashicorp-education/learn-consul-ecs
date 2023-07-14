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

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name
}