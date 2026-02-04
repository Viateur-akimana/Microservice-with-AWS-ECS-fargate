output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.loadbalancer.alb_dns_name
}

output "alb_url" {
  description = "Application Load Balancer URL"
  value       = module.loadbalancer.alb_url
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value       = module.compute.ecr_repositories
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.data.rds_endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.data.redis_endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = module.compute.ecs_cluster_name
}

output "service_discovery_namespace" {
  description = "Service discovery namespace"
  value       = module.compute.service_discovery_namespace
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value       = module.compute.cloudwatch_log_groups
}
