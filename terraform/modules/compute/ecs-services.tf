# User Service Task Definition
resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.project_name}-${var.environment}-user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = "${aws_ecr_repository.services["user-service"].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDIS_URL"
          value = local.redis_url
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.services["user-service"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service-task"
    Environment = var.environment
    Tier        = "application"
    Service     = "user-service"
  }
}

# User Service
resource "aws_ecs_service" "user_service" {
  name            = "user-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.user_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns["user-service"]
    container_name   = "user-service"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.services["user-service"].arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service"
    Environment = var.environment
    Tier        = "application"
    Service     = "user-service"
  }
}

# Order Service Task Definition
resource "aws_ecs_task_definition" "order_service" {
  family                   = "${var.project_name}-${var.environment}-order-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-service"
      image     = "${aws_ecr_repository.services["order-service"].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDIS_URL"
          value = local.redis_url
        },
        {
          name  = "USER_SERVICE_URL"
          value = "http://user-service.${var.project_name}-${var.environment}.local:8000"
        },
        {
          name  = "PAYMENT_SERVICE_URL"
          value = "http://payment-service.${var.project_name}-${var.environment}.local:8000"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.services["order-service"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-service-task"
    Environment = var.environment
    Tier        = "application"
    Service     = "order-service"
  }
}

# Order Service
resource "aws_ecs_service" "order_service" {
  name            = "order-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns["order-service"]
    container_name   = "order-service"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.services["order-service"].arn
  }

  depends_on = [aws_ecs_service.user_service]

  tags = {
    Name        = "${var.project_name}-${var.environment}-order-service"
    Environment = var.environment
    Tier        = "application"
    Service     = "order-service"
  }
}

# Payment Service Task Definition
resource "aws_ecs_task_definition" "payment_service" {
  family                   = "${var.project_name}-${var.environment}-payment-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "payment-service"
      image     = "${aws_ecr_repository.services["payment-service"].repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "LOG_LEVEL"
          value = "INFO"
        },
        {
          name  = "REDIS_URL"
          value = local.redis_url
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.db_secret_arn}:username::"
        },
        {
          name      = "JWT_SECRET"
          valueFrom = var.jwt_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.services["payment-service"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-service-task"
    Environment = var.environment
    Tier        = "application"
    Service     = "payment-service"
  }
}

# Payment Service
resource "aws_ecs_service" "payment_service" {
  name            = "payment-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.payment_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns["payment-service"]
    container_name   = "payment-service"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.services["payment-service"].arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-payment-service"
    Environment = var.environment
    Tier        = "application"
    Service     = "payment-service"
  }
}
