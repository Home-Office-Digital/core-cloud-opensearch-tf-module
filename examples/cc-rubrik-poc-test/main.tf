data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "account_access" {
  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions = ["es:*"]

    resources = [
      "arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.name}",
      "arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.name}/*",
    ]
  }

  dynamic "statement" {
    for_each = length(var.dashboard_allowed_cidrs) > 0 ? [1] : []

    content {
      sid    = "AllowDashboardsFromCidrs"
      effect = "Allow"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions = [
        "es:ESHttpGet",
        "es:ESHttpHead",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpPatch",
        "es:ESHttpDelete",
      ]

      resources = [
        "arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.name}",
        "arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.name}/*",
      ]

      condition {
        test     = "IpAddress"
        variable = "aws:SourceIp"
        values   = var.dashboard_allowed_cidrs
      }
    }
  }
}

module "opensearch" {
  source = "../.."

  name           = var.name
  engine_version = "OpenSearch_2.17"
  instance_type  = var.instance_type
  instance_count = var.instance_count

  ebs_enabled     = true
  ebs_volume_type = "gp3"
  ebs_volume_size = 20

  encrypt_at_rest_enabled         = true
  node_to_node_encryption_enabled = true
  enforce_https                   = true

  log_publishing_options = {
    ES_APPLICATION_LOGS = {
      enabled           = true
      retention_in_days = 14
    }
  }

  access_policy = data.aws_iam_policy_document.account_access.json
  cc_tags       = var.cc_tags
}