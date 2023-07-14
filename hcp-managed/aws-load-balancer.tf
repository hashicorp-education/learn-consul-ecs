resource "aws_lb" "ingress" {
  name               = "${local.name}-ingress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.aws_hcp_consul.security_group_id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "frontend-nginx" {
  name                 = "${local.name}-frontend-nginx"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = 10
}

resource "aws_lb_listener" "frontend-nginx" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-nginx.arn
  }
}

resource "aws_lb_listener_rule" "frontend-nginx" {
  listener_arn = aws_lb_listener.frontend-nginx.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend-nginx.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
  
}