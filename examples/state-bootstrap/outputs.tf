output "bucket_name" {
  description = "Name of the created S3 state bucket"
  value       = nonsensitive(module.state_bucket.bucket_id)
}

output "backend_hcl" {
  description = "Backend configuration values to copy into backend.hcl"
  value = {
    bucket       = nonsensitive(module.state_bucket.bucket_id)
    key          = "${var.state_key_prefix}terraform.tfstate"
    region       = var.region
    profile      = var.aws_profile
    encrypt      = true
    use_lockfile = true
  }
}

output "github_oidc_role_arn" {
  description = "IAM role ARN for GitHub OIDC workflow runs"
  value       = try(aws_iam_role.github_actions_terraform[0].arn, null)
}

output "github_oidc_policy_arn" {
  description = "IAM policy ARN attached to the GitHub OIDC role"
  value       = try(aws_iam_policy.github_actions_terraform[0].arn, null)
}
