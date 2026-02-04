variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS services"
  type        = string
}

variable "services" {
  description = "List of microservices"
  type        = list(string)
}

variable "rds_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of database secret"
  type        = string
}

variable "jwt_secret_arn" {
  description = "ARN of JWT secret"
  type        = string
}

variable "target_group_arns" {
  description = "Map of service names to target group ARNs"
  type        = map(string)
}
