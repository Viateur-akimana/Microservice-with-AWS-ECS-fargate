# Application Load Balancer (Presentation Tier)
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false # Set to true for production

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Tier        = "presentation"
  }
}

# Default Target Group
resource "aws_lb_target_group" "default" {
  name        = "${var.project_name}-${var.environment}-default-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-default-tg"
    Environment = var.environment
    Tier        = "presentation"
  }
}

# Target Groups for each microservice
resource "aws_lb_target_group" "services" {
  for_each = toset(var.services)

  name        = "${var.project_name}-${var.environment}-${each.key}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-tg"
    Environment = var.environment
    Tier        = "presentation"
    Service     = each.key
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    Tier        = "presentation"
  }
}

# Listener Rules for path-based routing
resource "aws_lb_listener_rule" "user_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["user-service"].arn
  }

  condition {
    path_pattern {
      values = ["/users/*", "/users"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service-rule"
    Environment = var.environment
    Service     = "user-service"
  }
}

resource "aws_lb_listener_rule" "order_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["order-service"].arn
  }

  condition {
    path_pattern {
      values = ["/orders/*", "/orders"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-service-rule"
    Environment = var.environment
    Service     = "order-service"
  }
}

resource "aws_lb_listener_rule" "payment_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["payment-service"].arn
  }

  condition {
    path_pattern {
      values = ["/payments/*", "/payments"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-service-rule"
    Environment = var.environment
    Service     = "payment-service"
  }
}
