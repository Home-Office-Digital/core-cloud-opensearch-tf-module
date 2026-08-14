# State Bootstrap Example

This example creates:

- an S3 bucket for Terraform remote state using the shared `core-cloud-s3-tf-module`
- a GitHub OIDC IAM role and policy for workflow plan and apply runs

Note: the S3 module provisions additional guardrail resources (for example log/replica bucket patterns) as part of its standard behavior.

## Why This Exists

Terraform backends are initialized before resource creation. If an S3 backend bucket does not already exist, `terraform init` fails.

Use this bootstrap once to create the bucket and role, then initialize other examples and configure the GitHub repository secrets used by the workflows.

## Required Input

`bucket_name` is the only required Terraform input. It must be globally unique and contain at least three hyphen-separated parts because the shared S3 module derives its project, bucket, and environment names from it.

For the current example, use `cc-rubrik-poc-test-tfstate-opensearch`. The bootstrap and workflow state settings must use the same bucket.

## Optional Inputs

| Input | Default | Use when |
|---|---|---|
| `aws_profile` | `CCRubrikPOCTest` | Using a different local AWS CLI or SSO profile |
| `region` | `eu-west-2` | Creating state in another AWS region |
| `state_key_prefix` | `opensearch/example/` | Storing this repository's Terraform state under another prefix |
| `email_address` | `core-cloud-opensearch@example.com` | Routing S3 module notifications to a real mailbox |
| `kms_alias` | Derived from `bucket_name` | Reusing a specific KMS alias |
| `s3_module_tags` | Core Cloud placeholder tags | Replacing placeholder tags with project values |
| `create_github_oidc_role` | `true` | Skipping OIDC role and policy creation |
| `github_repository` | `Home-Office-Digital/core-cloud-opensearch-tf-module` | Allowing another repository to assume the role |
| `github_branches` | `main`, `feature/CCL-10788-openseach-module` | Adding explicit branch subject patterns |
| `github_oidc_role_name` | `GitHubActionsTerraformOpenSearch` | Using a different IAM role name |
| `github_oidc_policy_name` | `GitHubActionsTerraformOpenSearchPolicy` | Using a different IAM policy name |

## Create Bootstrap Resources

```sh
aws sso login --profile CCRubrikPOCTest
terraform -chdir=examples/state-bootstrap init
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='aws_profile=CCRubrikPOCTest'
```

If you want SNS notifications routed to a real mailbox, override the default placeholder email:

```sh
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='aws_profile=CCRubrikPOCTest' \
	-var='email_address=platform-team@example.com'
```

View outputs:

```sh
terraform -chdir=examples/state-bootstrap output backend_hcl
terraform -chdir=examples/state-bootstrap output github_oidc_role_arn
terraform -chdir=examples/state-bootstrap output github_oidc_role_name
terraform -chdir=examples/state-bootstrap output github_oidc_policy_arn
```

## GitHub OIDC Trust

By default, the role trust policy allows GitHub OIDC subjects from this repository:

- Home-Office-Digital/core-cloud-opensearch-tf-module

It also includes explicit patterns for `main` and `feature/CCL-10788-openseach-module`, but the repository-wide patterns allow other branches, tags, and workflow subject variations from the same repository. `github_branches` adds patterns; it does not restrict the role to only those branches.

You can override these at apply time:

```sh
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='aws_profile=CCRubrikPOCTest' \
	-var='github_repository=Home-Office-Digital/core-cloud-opensearch-tf-module' \
	-var='github_branches=["main","feature/CCL-10788-openseach-module"]'
```

To create only the bucket and skip IAM role creation:

```sh
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='aws_profile=CCRubrikPOCTest' \
	-var='create_github_oidc_role=false'
```

## Configure GitHub Workflows

After a successful apply, configure these repository secrets:

| Secret | Value |
|---|---|
| `AWS_ACCOUNT_ID` | The 12-digit account ID returned by `aws sts get-caller-identity --profile CCRubrikPOCTest --query Account --output text` |
| `AWS_ROLE_TO_ASSUME` | The `github_oidc_role_name` output, for example `GitHubActionsTerraformOpenSearch` |

`AWS_ROLE_TO_ASSUME` must contain only the role name, not the `github_oidc_role_arn` value. The workflow action constructs the role ARN from both secrets.

Use these matching values when starting a workflow:

| Workflow input | Bootstrap value |
|---|---|
| `aws_region` | `region` |
| `state_bucket` | `bucket_name` output |
| `state_key` | `state_key_prefix` followed by `terraform.tfstate` |
| `state_dynamodb_table` | Leave empty unless you manage a lock table separately |

See [.github/workflows/README.md](../../.github/workflows/README.md) for workflow plan, apply, and destroy instructions.

When no longer needed:

```sh
terraform -chdir=examples/state-bootstrap destroy \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='aws_profile=CCRubrikPOCTest'
```

Note: S3 bucket names are globally unique. If the name is already taken, choose a different one.