output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.this.arn
}

output "domain_id" {
  description = "Unique identifier for the OpenSearch domain"
  value       = aws_opensearch_domain.this.domain_id
}

output "domain_endpoint" {
  description = "Endpoint used for index, search, and ingest traffic"
  value       = aws_opensearch_domain.this.endpoint
}

output "dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = aws_opensearch_domain.this.dashboard_endpoint
}

output "log_group_names" {
  description = "Names of CloudWatch log groups managed by the module"
  value       = [for log_group in aws_cloudwatch_log_group.this : log_group.name]
}

