locals {
  common_tags = {
    cost-centre      = var.cc_tags.cost_centre
    account-code     = var.cc_tags.account_code
    portfolio-id     = var.cc_tags.portfolio_id
    project-id       = var.cc_tags.project_id
    service-id       = var.cc_tags.service_id
    environment-type = var.cc_tags.environment_type
    owner-business   = var.cc_tags.owner_business
    budget-holder    = var.cc_tags.budget_holder
  }

  merged_tags = merge(
    local.common_tags,
    {
      Name = var.name
    },
    var.tags,
  )

  create_vpc_options = length(var.subnet_ids) > 0

  enabled_log_publishing_options = {
    for log_type, config in var.log_publishing_options : log_type => {
      retention_in_days = try(config.retention_in_days, var.log_group_retention_in_days)
      kms_key_id        = try(config.kms_key_id, null)
    } if config.enabled
  }

  create_log_resource_policy = var.manage_cloudwatch_log_resource_policy && length(local.enabled_log_publishing_options) > 0
}

data "aws_iam_policy_document" "cloudwatch_log_delivery" {
  count = local.create_log_resource_policy ? 1 : 0

  statement {
    sid    = "AllowOpenSearchLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [for log_group in aws_cloudwatch_log_group.this : "${log_group.arn}:*"]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.enabled_log_publishing_options

  name              = "/aws/opensearch/domains/${var.name}/${each.key}"
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id

  tags = local.merged_tags
}

resource "aws_cloudwatch_log_resource_policy" "this" {
  count = local.create_log_resource_policy ? 1 : 0

  policy_name     = var.cloudwatch_log_resource_policy_name != null ? var.cloudwatch_log_resource_policy_name : "${var.name}-opensearch-log-delivery"
  policy_document = data.aws_iam_policy_document.cloudwatch_log_delivery[0].json
}

resource "aws_opensearch_domain" "this" {
  domain_name    = var.name
  engine_version = var.engine_version

  cluster_config {
    dedicated_master_enabled      = var.dedicated_master_enabled
    dedicated_master_count        = var.dedicated_master_enabled ? var.dedicated_master_count : null
    dedicated_master_type         = var.dedicated_master_enabled ? var.dedicated_master_type : null
    instance_count                = var.instance_count
    instance_type                 = var.instance_type
    multi_az_with_standby_enabled = var.multi_az_with_standby_enabled
    warm_enabled                  = var.warm_enabled
    warm_count                    = var.warm_enabled ? var.warm_count : null
    warm_type                     = var.warm_enabled ? var.warm_type : null
    zone_awareness_enabled        = var.zone_awareness_enabled

    dynamic "zone_awareness_config" {
      for_each = var.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.zone_awareness_count
      }
    }
  }

  dynamic "advanced_security_options" {
    for_each = var.advanced_security_options_enabled ? [1] : []
    content {
      anonymous_auth_enabled         = var.anonymous_auth_enabled
      enabled                        = true
      internal_user_database_enabled = var.internal_user_database_enabled

      master_user_options {
        master_user_arn      = var.master_user_arn
        master_user_name     = var.master_user_name
        master_user_password = var.master_user_password
      }
    }
  }

  dynamic "ebs_options" {
    for_each = var.ebs_enabled ? [1] : []
    content {
      ebs_enabled = true
      volume_size = var.ebs_volume_size
      volume_type = var.ebs_volume_type
      iops        = contains(["gp3", "io1"], var.ebs_volume_type) ? var.ebs_iops : null
      throughput  = var.ebs_volume_type == "gp3" ? var.ebs_throughput : null
    }
  }

  encrypt_at_rest {
    enabled    = var.encrypt_at_rest_enabled
    kms_key_id = var.kms_key_id
  }

  node_to_node_encryption {
    enabled = var.node_to_node_encryption_enabled
  }

  snapshot_options {
    automated_snapshot_start_hour = var.automated_snapshot_start_hour
  }

  dynamic "vpc_options" {
    for_each = local.create_vpc_options ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  domain_endpoint_options {
    enforce_https                   = var.enforce_https
    tls_security_policy             = var.tls_security_policy
    custom_endpoint_enabled         = var.custom_endpoint != null
    custom_endpoint                 = var.custom_endpoint
    custom_endpoint_certificate_arn = var.custom_endpoint_certificate_arn
  }

  dynamic "log_publishing_options" {
    for_each = local.enabled_log_publishing_options
    content {
      enabled                  = true
      log_type                 = log_publishing_options.key
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.this[log_publishing_options.key].arn
    }
  }

  tags = local.merged_tags
}

resource "aws_opensearch_domain_policy" "this" {
  count = trimspace(var.access_policy) != "" ? 1 : 0

  domain_name     = aws_opensearch_domain.this.domain_name
  access_policies = var.access_policy
}
