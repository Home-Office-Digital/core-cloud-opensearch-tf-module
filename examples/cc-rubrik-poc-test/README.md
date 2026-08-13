# CCRubrikPOCTest Example

This example is a thin root module for deploying the child module into the `CCRubrikPOCTest` AWS SSO profile.

It is intended for quick Rubrik test-account validation and defaults to a low-cost single-node deployment. For production-style usage, prefer a VPC-backed configuration and stricter access policy inputs from the calling stack.

## Quick Start

Use the helper script to choose state mode and initialize the example.

AWS login
```sh
aws sso login --profile CCRubrikPOCTest
```

Local state:

```sh
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=false
terraform -chdir=examples/cc-rubrik-poc-test plan
```

Remote state (S3 bucket + backend):

```sh
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true create-bucket=true
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true
terraform -chdir=examples/cc-rubrik-poc-test plan
```

Behavior summary for `state-bucket=true`:

- By default, it does not create resources. It only initializes backend using an existing bucket.
- If the bucket is missing or inaccessible, it fails and tells you how to create it.
- Use `create-bucket=true` to explicitly create or reconcile the bucket via the bootstrap example.
- If the bucket name is already taken globally by another account, bucket creation fails and you must pass a different `bucket-name`.

Remote state with explicit values:

```sh
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true create-bucket=true bucket-name=cc-rubrik-poc-test-tfstate-opensearch profile=CCRubrikPOCTest region=eu-west-2
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true bucket-name=cc-rubrik-poc-test-tfstate-opensearch profile=CCRubrikPOCTest region=eu-west-2
terraform -chdir=examples/cc-rubrik-poc-test plan
```

## Defaults

- AWS profile: empty (uses environment credentials/OIDC); for local SSO use `CCRubrikPOCTest`
- Region: `eu-west-2`
- Domain name: `cc-rubrik-poc-test`
- Instance type: `t3.small.search`
- Instance count: `1`

## Commands

```sh
terraform -chdir=examples/cc-rubrik-poc-test plan
terraform -chdir=examples/cc-rubrik-poc-test apply
terraform -chdir=examples/cc-rubrik-poc-test destroy
```

Note: run one of the init-state commands first. Do not run plain `terraform init` before choosing local or remote mode.

## GitHub Actions Deployment Workflow

This repo includes split workflows for plan/apply/destroy:

- Plan workflow: [.github/workflows/example-cc-rubrik-poc-test-deploy.yaml](.github/workflows/example-cc-rubrik-poc-test-deploy.yaml)
	- Triggers:
	- `push` to `feature/CCL-10788-openseach-module`
	- `workflow_dispatch` for manual plan runs
- Apply workflow: [.github/workflows/example-cc-rubrik-poc-test-apply.yaml](.github/workflows/example-cc-rubrik-poc-test-apply.yaml)
	- Triggers:
	- `workflow_run` when `Example CCRubrikPOCTest Plan` completes successfully on `feature/CCL-10788-openseach-module`
	- Trigger: `workflow_dispatch` only
	- Safeguards:
	- runs only on `apply_branch`
	- `confirm_apply` must be `APPLY`
- Destroy workflow: [.github/workflows/example-cc-rubrik-poc-test-destroy.yaml](.github/workflows/example-cc-rubrik-poc-test-destroy.yaml)
	- Trigger: `workflow_dispatch` only
	- Safeguards:
	- runs only on `apply_branch`
	- `confirm_destroy` must be `DESTROY`

For push-triggered plan runs, set the role name in [.github/workflows/example-cc-rubrik-poc-test-deploy.yaml](.github/workflows/example-cc-rubrik-poc-test-deploy.yaml) to your GitHub OIDC role (for example: GitHubActionsTerraformOpenSearch).

Common required inputs when running apply/destroy workflows:

- `working_directory` (default `./examples/cc-rubrik-poc-test`)
- `account_id` (default `118490267426`)
- `aws_region` (default `eu-west-2`)
- `state_bucket` (default `cc-rubrik-poc-test-tfstate-opensearch`)
- `state_key` (default `opensearch/example/terraform.tfstate`)
- `state_dynamodb_table` (optional, default empty)
- `role_to_assume` (OIDC role name used by Core Cloud terraform actions)
- `apply_branch` (branch allowed to execute apply/destroy, default `main`)

Operation-specific confirmations:

- Apply workflow requires `confirm_apply=APPLY`
- Destroy workflow requires `confirm_destroy=DESTROY`

## Advanced: Manual Backend Commands

Use this only if you do not want to use [examples/cc-rubrik-poc-test/init-state.sh](examples/cc-rubrik-poc-test/init-state.sh).

This example is configured with an S3 backend block. If you initialize Terraform directly for remote mode, the state bucket must already exist.

If the bucket does not exist yet, create it first using [examples/state-bootstrap/README.md](examples/state-bootstrap/README.md).

Bootstrap example:

```sh
terraform -chdir=examples/state-bootstrap init
terraform -chdir=examples/state-bootstrap apply -var='bucket_name=cc-rubrik-poc-test-tfstate-opensearch'
terraform -chdir=examples/state-bootstrap output github_oidc_role_arn
```

Example backend configuration file is provided at [examples/cc-rubrik-poc-test/backend.hcl.example](examples/cc-rubrik-poc-test/backend.hcl.example).

Initialize with backend settings:

```sh
terraform -chdir=examples/cc-rubrik-poc-test init -reconfigure -backend-config=backend.hcl.example
```

If you are migrating from local state, run:

```sh
terraform -chdir=examples/cc-rubrik-poc-test init -migrate-state -reconfigure -backend-config=backend.hcl.example
```

If you prefer using the helper script for migration:

```sh
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true create-bucket=true
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true migrate-state=true
```

## Dashboards Access From Browser

By default, direct browser requests are unsigned and are treated as anonymous, so they are denied by the account-principal access policy.

For temporary PoC access, allow your current public IP as a CIDR:

```sh
terraform -chdir=examples/cc-rubrik-poc-test apply -var='dashboard_allowed_cidrs=["203.0.113.10/32"]'
```

When done testing, remove that access and apply again:

```sh
terraform -chdir=examples/cc-rubrik-poc-test apply -var='dashboard_allowed_cidrs=[]'
```

## Instance Type Variants

To validate a second instance type without editing files:

```sh
terraform -chdir=examples/cc-rubrik-poc-test plan -var='instance_type=t3.medium.search'
terraform -chdir=examples/cc-rubrik-poc-test apply -var='instance_type=t3.medium.search'
```