output "cluster_id" {
  description = "ID of the created ECS Cluster."
  value       = module.ecs.cluster_id
}

output "cluster_arn" {
  description = "ARN of the created ECS Cluster."
  value       = module.ecs.cluster_arn
}

output "cluster_name" {
  description = "Name of the created ECS Cluster."
  value       = module.ecs.cluster_name
}

output "services" {
  description = "Map of services created and their attributes."
  value       = module.ecs.services
}
