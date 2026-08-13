variable "name" {
  description = "Name of the OpenSearch domain"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cc_tags" {
  description = "Core Cloud mandatory tagging values"
  type = object({
    cost_centre      = string
    account_code     = string
    portfolio_id     = string
    project_id       = string
    service_id       = string
    environment_type = string
    owner_business   = string
    budget_holder    = string
  })
}

variable "tags" {
  description = "Additional tags merged on top of the mandatory Core Cloud tags"
  type        = map(string)
  default     = {}
}

variable "engine_version" {
  description = "OpenSearch or legacy Elasticsearch engine version, for example OpenSearch_2.17"
  type        = string
  default     = "OpenSearch_2.17"

  validation {
    condition     = can(regex("^(OpenSearch|Elasticsearch)_", var.engine_version))
    error_message = "engine_version must start with OpenSearch_ or Elasticsearch_."
  }
}

variable "instance_type" {
  description = "Instance type for data nodes"
  type        = string
  default     = "m6g.large.search"

  validation {
    condition     = can(regex("\\.search$", var.instance_type))
    error_message = "instance_type must be an OpenSearch instance type ending with .search."
  }
}

variable "instance_count" {
  description = "Number of data nodes in the domain"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1
    error_message = "instance_count must be at least 1."
  }
}

variable "dedicated_master_enabled" {
  description = "Whether to use dedicated master nodes"
  type        = bool
  default     = false
}

variable "dedicated_master_count" {
  description = "Number of dedicated master nodes when dedicated masters are enabled"
  type        = number
  default     = 3

  validation {
    condition     = !var.dedicated_master_enabled || var.dedicated_master_count >= 3
    error_message = "dedicated_master_count must be at least 3 when dedicated_master_enabled is true."
  }
}

variable "dedicated_master_type" {
  description = "Instance type for dedicated master nodes"
  type        = string
  default     = "m6g.large.search"

  validation {
    condition     = !var.dedicated_master_enabled || can(regex("\\.search$", var.dedicated_master_type))
    error_message = "dedicated_master_type must be set to an OpenSearch instance type when dedicated masters are enabled."
  }
}

variable "warm_enabled" {
  description = "Whether UltraWarm nodes are enabled"
  type        = bool
  default     = false
}

variable "warm_count" {
  description = "Number of UltraWarm nodes when warm_enabled is true"
  type        = number
  default     = 2

  validation {
    condition     = !var.warm_enabled || var.warm_count >= 2
    error_message = "warm_count must be at least 2 when warm_enabled is true."
  }
}

variable "warm_type" {
  description = "Instance type for UltraWarm nodes"
  type        = string
  default     = "ultrawarm1.medium.search"

  validation {
    condition     = !var.warm_enabled || can(regex("\\.search$", var.warm_type))
    error_message = "warm_type must be set to an OpenSearch instance type when warm_enabled is true."
  }
}

variable "zone_awareness_enabled" {
  description = "Whether zone awareness is enabled"
  type        = bool
  default     = false
}

variable "zone_awareness_count" {
  description = "Availability zone count used when zone awareness is enabled"
  type        = number
  default     = 2

  validation {
    condition     = !var.zone_awareness_enabled || contains([2, 3], var.zone_awareness_count)
    error_message = "zone_awareness_count must be either 2 or 3 when zone awareness is enabled."
  }
}

variable "multi_az_with_standby_enabled" {
  description = "Whether to enable multi-AZ with standby"
  type        = bool
  default     = false
}

variable "ebs_enabled" {
  description = "Whether to attach EBS storage to data nodes"
  type        = bool
  default     = true
}

variable "ebs_volume_size" {
  description = "EBS volume size in GiB"
  type        = number
  default     = 20

  validation {
    condition     = !var.ebs_enabled || var.ebs_volume_size >= 10
    error_message = "ebs_volume_size must be at least 10 when ebs_enabled is true."
  }
}

variable "ebs_volume_type" {
  description = "EBS volume type for data nodes"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "standard"], var.ebs_volume_type)
    error_message = "ebs_volume_type must be one of gp2, gp3, io1, or standard."
  }
}

variable "ebs_iops" {
  description = "Provisioned IOPS used for gp3 and io1 volumes"
  type        = number
  default     = 3000

  validation {
    condition     = !var.ebs_enabled || var.ebs_iops >= 0
    error_message = "ebs_iops must be zero or greater."
  }
}

variable "ebs_throughput" {
  description = "Provisioned throughput in MiB/s for gp3 volumes"
  type        = number
  default     = 125

  validation {
    condition     = !var.ebs_enabled || var.ebs_throughput >= 0
    error_message = "ebs_throughput must be zero or greater."
  }
}

variable "encrypt_at_rest_enabled" {
  description = "Whether to enable encryption at rest"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional KMS key ID or ARN for encryption at rest"
  type        = string
  default     = null
  nullable    = true
}

variable "node_to_node_encryption_enabled" {
  description = "Whether to enable node-to-node encryption"
  type        = bool
  default     = true
}

variable "enforce_https" {
  description = "Whether to require HTTPS for the domain endpoint"
  type        = bool
  default     = true
}

variable "tls_security_policy" {
  description = "TLS security policy for the domain endpoint"
  type        = string
  default     = "Policy-Min-TLS-1-2-2019-07"

  validation {
    condition     = contains(["Policy-Min-TLS-1-0-2019-07", "Policy-Min-TLS-1-2-2019-07"], var.tls_security_policy)
    error_message = "tls_security_policy must be Policy-Min-TLS-1-0-2019-07 or Policy-Min-TLS-1-2-2019-07."
  }
}

variable "automated_snapshot_start_hour" {
  description = "UTC hour for automated snapshots"
  type        = number
  default     = 0

  validation {
    condition     = var.automated_snapshot_start_hour >= 0 && var.automated_snapshot_start_hour <= 23
    error_message = "automated_snapshot_start_hour must be between 0 and 23."
  }
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC deployment"
  type        = list(string)
  default     = []

  validation {
    condition     = (length(var.subnet_ids) == 0 && length(var.security_group_ids) == 0) || (length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0)
    error_message = "subnet_ids and security_group_ids must either both be set or both be empty."
  }
}

variable "security_group_ids" {
  description = "Security group IDs for VPC deployment"
  type        = list(string)
  default     = []
}

variable "advanced_security_options_enabled" {
  description = "Whether to enable advanced security options"
  type        = bool
  default     = false
}

variable "anonymous_auth_enabled" {
  description = "Whether to allow anonymous auth while fine-grained access control is enabled"
  type        = bool
  default     = false
}

variable "internal_user_database_enabled" {
  description = "Whether to enable the internal user database for fine-grained access control"
  type        = bool
  default     = false
}

variable "master_user_arn" {
  description = "Optional IAM ARN for the domain master user"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = !var.advanced_security_options_enabled || (
      ((var.master_user_arn != null ? 1 : 0) + ((var.master_user_name != null && var.master_user_password != null) ? 1 : 0)) == 1
    )
    error_message = "When advanced_security_options_enabled is true, set either master_user_arn or both master_user_name and master_user_password."
  }
}

variable "master_user_name" {
  description = "Optional master user name when using the internal user database"
  type        = string
  default     = null
  nullable    = true
}

variable "master_user_password" {
  description = "Optional master user password when using the internal user database"
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "custom_endpoint" {
  description = "Optional custom endpoint hostname"
  type        = string
  default     = null
  nullable    = true
}

variable "custom_endpoint_certificate_arn" {
  description = "ACM certificate ARN used when custom_endpoint is configured"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.custom_endpoint == null || var.custom_endpoint_certificate_arn != null
    error_message = "custom_endpoint_certificate_arn must be provided when custom_endpoint is set."
  }
}

variable "log_group_retention_in_days" {
  description = "Default retention period applied to module-managed log groups"
  type        = number
  default     = 30
}

variable "log_publishing_options" {
  description = "Log publishing configuration keyed by OpenSearch log type"
  type = map(object({
    enabled           = bool
    retention_in_days = optional(number)
    kms_key_id        = optional(string)
  }))
  default = {
    INDEX_SLOW_LOGS = {
      enabled = false
    }
    SEARCH_SLOW_LOGS = {
      enabled = false
    }
    ES_APPLICATION_LOGS = {
      enabled = false
    }
    AUDIT_LOGS = {
      enabled = false
    }
  }

  validation {
    condition = alltrue([
      for log_type in keys(var.log_publishing_options) : contains([
        "INDEX_SLOW_LOGS",
        "SEARCH_SLOW_LOGS",
        "ES_APPLICATION_LOGS",
        "AUDIT_LOGS"
      ], log_type)
    ])
    error_message = "log_publishing_options keys must be valid OpenSearch log types."
  }
}

variable "manage_cloudwatch_log_resource_policy" {
  description = "Whether the module should manage the CloudWatch Logs resource policy used for OpenSearch log delivery"
  type        = bool
  default     = true
}

variable "cloudwatch_log_resource_policy_name" {
  description = "Optional explicit name for the CloudWatch Logs resource policy"
  type        = string
  default     = null
  nullable    = true
}

variable "access_policy" {
  description = "Optional JSON access policy for the domain. Leave empty to skip policy creation."
  type        = string
  default     = ""
}
