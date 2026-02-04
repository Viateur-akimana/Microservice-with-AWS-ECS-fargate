output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "service_discovery_namespace" {
  description = "Service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = {
    for service, log_group in aws_cloudwatch_log_group.services :
    service => log_group.name
  }
}

output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    for service, repo in aws_ecr_repository.services :
    service => repo.repository_url
  }
}

output "ecs_service_names" {
  description = "ECS service names"
  value = {
    user-service    = aws_ecs_service.user_service.name
    order-service   = aws_ecs_service.order_service.name
    payment-service = aws_ecs_service.payment_service.name
  }
}
