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

- AWS profile: `CCRubrikPOCTest`
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

This repo includes a manual workflow for the example deployment:

- Workflow file: [ .github/workflows/example-cc-rubrik-poc-test-deploy.yaml ](.github/workflows/example-cc-rubrik-poc-test-deploy.yaml)
- Triggers:
	- `push` to `feature/CCL-10788-openseach-module` (runs plan only)
	- `workflow_dispatch` (plan or apply)
- Operations: `plan` or `apply`

Apply safeguards in the workflow:

- `apply` runs only on `main`
- `confirm_apply` must be set to `APPLY`

For push-triggered plan runs, set the role name in [.github/workflows/example-cc-rubrik-poc-test-deploy.yaml](.github/workflows/example-cc-rubrik-poc-test-deploy.yaml) to your GitHub OIDC role (for example: GitHubActionsTerraformOpenSearch).

Required inputs when running the workflow:

- `working_directory` (default `./examples/cc-rubrik-poc-test`)
- `account_id` (default `118490267426`)
- `aws_region` (default `eu-west-2`)
- `role_to_assume` (OIDC role name used by Core Cloud terraform actions)

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