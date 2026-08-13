# State Bootstrap Example

This example creates:

- an S3 bucket for Terraform remote state using the shared `core-cloud-s3-tf-module`
- a GitHub OIDC IAM role and policy for workflow plan and apply runs

Note: the S3 module provisions additional guardrail resources (for example log/replica bucket patterns) as part of its standard behavior.

## Why This Exists

Terraform backends are initialized before resource creation. If an S3 backend bucket does not already exist, `terraform init` fails.

Use this bootstrap once to create the bucket and role, then initialize other examples and wire the role ARN into the workflow.

## Commands

```sh
terraform -chdir=examples/state-bootstrap init
terraform -chdir=examples/state-bootstrap apply -var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch'
```

View outputs:

```sh
terraform -chdir=examples/state-bootstrap output backend_hcl
terraform -chdir=examples/state-bootstrap output github_oidc_role_arn
terraform -chdir=examples/state-bootstrap output github_oidc_policy_arn
```

By default, role trust is restricted to this repository and these branches:

- Home-Office-Digital/core-cloud-opensearch-tf-module
- main
- feature/CCL-10788-openseach-module

You can override these at apply time:

```sh
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='github_repository=Home-Office-Digital/core-cloud-opensearch-tf-module' \
	-var='github_branches=["main","feature/CCL-10788-openseach-module"]'
```

To create only the bucket and skip IAM role creation:

```sh
terraform -chdir=examples/state-bootstrap apply \
	-var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch' \
	-var='create_github_oidc_role=false'
```

After creation, set the role ARN in [.github/workflows/example-cc-rubrik-poc-test-deploy.yaml](.github/workflows/example-cc-rubrik-poc-test-deploy.yaml) by replacing:

- arn:aws:iam::118490267426:role/REPLACE_WITH_GITHUB_OIDC_ROLE

When no longer needed:

```sh
terraform -chdir=examples/state-bootstrap destroy -var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch'
```

Note: S3 bucket names are globally unique. If the name is already taken, choose a different one.