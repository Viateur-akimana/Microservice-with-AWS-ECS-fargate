# Get IAM roles from security module
data "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
}

data "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"
}

# ECS Cluster (Application Tier)
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Tier        = "application"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "services" {
  for_each = toset(var.services)

  name              = "/ecs/${var.project_name}-${var.environment}/${each.key}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-logs"
    Environment = var.environment
    Tier        = "application"
    Service     = each.key
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name = "${var.project_name}-${var.environment}.local"
  vpc  = var.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-service-discovery"
    Environment = var.environment
    Tier        = "application"
  }
}

# Service Discovery Services
resource "aws_service_discovery_service" "services" {
  for_each = toset(var.services)

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.key}-discovery"
    Environment = var.environment
    Tier        = "application"
    Service     = each.key
  }
}

# ECR Repositories
resource "aws_ecr_repository" "services" {
  for_each = toset(var.services)

  name                 = "${var.project_name}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${each.key}"
    Environment = var.environment
    Tier        = "application"
    Service     = each.key
  }
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "services" {
  for_each   = aws_ecr_repository.services
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

locals {
  redis_url = "redis://${split(":", var.redis_endpoint)[0]}:${split(":", var.redis_endpoint)[1]}"
}

# ECS Task Definitions and Services are in separate files for better organization
