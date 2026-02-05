variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "db_name" {
  description = "Primary database name"
  type        = string
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
}

variable "services" {
  description = "List of microservices"
  type        = list(string)
}
