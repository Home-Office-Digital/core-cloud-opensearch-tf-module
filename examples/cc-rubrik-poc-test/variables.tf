variable "aws_profile" {
  description = "Optional AWS CLI profile used for deployment; leave empty to use environment/OIDC credentials"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region used for deployment"
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  description = "OpenSearch domain name used for the Rubrik PoC deployment"
  type        = string
  default     = "cc-rubrik-poc-test"
}

variable "instance_type" {
  description = "Data node instance type used by the example deployment"
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "Number of data nodes used by the example deployment"
  type        = number
  default     = 1
}

variable "dashboard_allowed_cidrs" {
  description = "Optional CIDR ranges allowed to access OpenSearch Dashboards directly from a browser"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.dashboard_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "dashboard_allowed_cidrs must contain valid CIDR blocks, for example 203.0.113.10/32."
  }
}

variable "cc_tags" {
  description = "Core Cloud mandatory tags for the example deployment"
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
  default = {
    cost_centre      = "cc-001"
    account_code     = "ac-001"
    portfolio_id     = "pf-001"
    project_id       = "pr-001"
    service_id       = "sv-001"
    environment_type = "test"
    owner_business   = "phoenix"
    budget_holder    = "core-cloud"
  }
}