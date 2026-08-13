output "domain_arn" {
  description = "ARN of the PoC OpenSearch domain"
  value       = module.opensearch.domain_arn
}

output "domain_endpoint" {
  description = "Endpoint of the PoC OpenSearch domain"
  value       = module.opensearch.domain_endpoint
}

output "dashboard_endpoint" {
  description = "Dashboards endpoint of the PoC OpenSearch domain"
  value       = module.opensearch.dashboard_endpoint
}