data "aws_caller_identity" "current" {}

locals {
  bucket_name_parts = split("-", var.bucket_name)
  project_name      = join("-", slice(local.bucket_name_parts, 0, length(local.bucket_name_parts) - 2))
  module_bucket     = local.bucket_name_parts[length(local.bucket_name_parts) - 2]
  environment       = local.bucket_name_parts[length(local.bucket_name_parts) - 1]
  repo_owner        = split("/", var.github_repository)[0]
  repo_name         = split("/", var.github_repository)[1]
  repo_owner_lower  = lower(local.repo_owner)
  repo_name_lower   = lower(local.repo_name)
}

module "state_bucket" {
  source = "git::https://github.com/Home-Office-Digital/core-cloud-s3-tf-module.git?ref=main"

  account_id      = data.aws_caller_identity.current.account_id
  bucket_name     = local.module_bucket
  project_name    = local.project_name
  environment     = local.environment
  region          = var.region
  kms_alias       = var.kms_alias != null ? var.kms_alias : "${replace(var.bucket_name, ".", "-")}-kms"
  enable_versioning = true
  encryption_type = "AES256"
  email_address   = var.email_address
  tags            = var.s3_module_tags
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  count = var.create_github_oidc_role ? 1 : 0

  statement {
    sid     = "GitHubActionsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = concat(
        [
          "repo:${var.github_repository}:*",
          "repo:${lower(var.github_repository)}:*",
          "repo:${local.repo_owner}@*/${local.repo_name}@*:*",
          "repo:${local.repo_owner_lower}@*/${local.repo_name_lower}@*:*",
        ],
        [for branch in var.github_branches : "repo:${var.github_repository}:ref:refs/heads/${branch}"],
        [for branch in var.github_branches : "repo:${lower(var.github_repository)}:ref:refs/heads/${branch}"],
        [for branch in var.github_branches : "repo:${local.repo_owner}@*/${local.repo_name}@*:ref:refs/heads/${branch}"],
        [for branch in var.github_branches : "repo:${local.repo_owner_lower}@*/${local.repo_name_lower}@*:ref:refs/heads/${branch}"]
      )
    }
  }
}

resource "aws_iam_role" "github_actions_terraform" {
  count = var.create_github_oidc_role ? 1 : 0

  name               = var.github_oidc_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[0].json
}

data "aws_iam_policy_document" "github_actions_terraform_permissions" {
  count = var.create_github_oidc_role ? 1 : 0

  statement {
    sid = "OpenSearchDomainManagement"
    actions = [
      "es:CreateDomain",
      "es:DeleteDomain",
      "es:DescribeDomain",
      "es:DescribeDomainConfig",
      "es:DescribeDomainChangeProgress",
      "es:UpdateDomainConfig",
      "es:ListDomainNames",
      "es:AddTags",
      "es:RemoveTags",
      "es:ListTags",
    ]
    resources = ["*"]
  }

  statement {
    sid = "CloudWatchLogsForOpenSearch"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DescribeLogGroups",
      "logs:TagLogGroup",
      "logs:UntagLogGroup",
      "logs:PutResourcePolicy",
      "logs:DescribeResourcePolicies",
      "logs:DeleteResourcePolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid = "CreateServiceLinkedRoleForOpenSearch"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["es.amazonaws.com"]
    }
  }

  statement {
    sid = "TfStateBucketMeta"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
    ]
    resources = [
      nonsensitive(module.state_bucket.bucket_arn),
    ]
  }

  statement {
    sid = "TfStateObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${nonsensitive(module.state_bucket.bucket_arn)}/${var.state_key_prefix}*",
    ]
  }
}

resource "aws_iam_policy" "github_actions_terraform" {
  count = var.create_github_oidc_role ? 1 : 0

  name   = var.github_oidc_policy_name
  policy = data.aws_iam_policy_document.github_actions_terraform_permissions[0].json
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  count = var.create_github_oidc_role ? 1 : 0

  role       = aws_iam_role.github_actions_terraform[0].name
  policy_arn = aws_iam_policy.github_actions_terraform[0].arn
}
