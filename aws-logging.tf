resource "aws_cloudwatch_log_group" "log_group" {
  name = local.name
}

/*
resource "aws_cloudwatch_log_stream" "product_api_log_stream" {
  name           = "product_api_log_stream"
  log_group_name = aws_cloudwatch_log_group.log_group.name
}
*/

locals {
  product_api_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-create-group = "true"
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "product_api"
    }
  }

  product_api_db_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-create-group = "true"
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "product_api_db"
    }
  }

  payments_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-create-group = "true"
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "payments"
    }
  }

  acl_controller_log_config = {
    logDriver = "awslogs"
    options = {
      awslogs-create-group = "true"
      awslogs-group         = aws_cloudwatch_log_group.log_group.name
      awslogs-region        = var.vpc_region
      awslogs-stream-prefix = "consul-acl-controller"
    }
  }
}