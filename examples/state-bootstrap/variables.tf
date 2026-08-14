variable "aws_profile" {
  description = "AWS CLI profile used for creating the state bucket"
  type        = string
  default     = "AWS_PROFILE_NAME"
}

variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "eu-west-2"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state"
  type        = string

  validation {
    condition     = length(split("-", var.bucket_name)) >= 3
    error_message = "bucket_name must contain at least three hyphen-separated parts so it can map to project_name-bucket_name-environment for core-cloud-s3-tf-module."
  }
}

variable "force_destroy" {
  description = "Deprecated: kept for backward compatibility, not used when S3 module manages bucket lifecycle"
  type        = bool
  default     = false
}

variable "state_key_prefix" {
  description = "Object prefix inside the state bucket used by this repository"
  type        = string
  default     = "opensearch/example/"
}

variable "kms_alias" {
  description = "Optional KMS alias for the S3 module bucket key; defaults to a derived alias from bucket_name"
  type        = string
  default     = null
}

variable "email_address" {
  description = "Shared project mailbox for S3 module notifications"
  type        = string
  default     = "core-cloud-opensearch@example.com"

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.email_address))
    error_message = "email_address must be a valid email format, for example team@example.com."
  }
}

variable "s3_module_tags" {
  description = "Tags passed to core-cloud-s3-tf-module. Must include mandatory Core Cloud keys required by that module."
  type        = map(string)
  default = {
    cost-centre      = "CCUNKNOWN"
    account-code     = "ACUNKNOWN"
    portfolio-id     = "PFUNKNOWN"
    project-id       = "PRUNKNOWN"
    service-id       = "SVUNKNOWN"
    environment-type = "shared"
    owner-business   = "core-cloud"
    budget-holder    = "core-cloud"
    source-repo      = "Home-Office-Digital/core-cloud-opensearch-tf-module"
    hosting-platform = "github-actions"
  }
}

variable "create_github_oidc_role" {
  description = "Whether to create a GitHub OIDC IAM role and policy for Terraform workflow runs"
  type        = bool
  default     = true
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the role, in owner/repo format"
  type        = string
  default     = "Home-Office-Digital/core-cloud-opensearch-tf-module"
}

variable "github_branches" {
  description = "Branch names allowed to assume the role"
  type        = list(string)
  default = [
    "main",
    "feature/CCL-10788-openseach-module",
  ]
}

variable "github_oidc_role_name" {
  description = "Name of the IAM role used by GitHub Actions via OIDC"
  type        = string
  default     = "GitHubActionsTerraformOpenSearch"
}

variable "github_oidc_policy_name" {
  description = "Name of the IAM policy attached to the GitHub OIDC role"
  type        = string
  default     = "GitHubActionsTerraformOpenSearchPolicy"
}
