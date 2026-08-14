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
terraform -chdir=examples/cc-rubrik-poc-test plan -var='aws_profile=CCRubrikPOCTest'
```

Remote state (S3 bucket + backend):

```sh
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true create-bucket=true
./examples/cc-rubrik-poc-test/init-state.sh state-bucket=true
terraform -chdir=examples/cc-rubrik-poc-test plan -var='aws_profile=CCRubrikPOCTest'
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
terraform -chdir=examples/cc-rubrik-poc-test plan -var='aws_profile=CCRubrikPOCTest'
```

## Defaults

- AWS profile: empty (uses environment credentials/OIDC); for local SSO use `CCRubrikPOCTest`
- Region: `eu-west-2`
- Domain name: `cc-rubrik-poc-test`
- Instance type: `t3.small.search`
- Instance count: `1`

## Commands

```sh
terraform -chdir=examples/cc-rubrik-poc-test plan -var='aws_profile=CCRubrikPOCTest'
terraform -chdir=examples/cc-rubrik-poc-test apply -var='aws_profile=CCRubrikPOCTest'
terraform -chdir=examples/cc-rubrik-poc-test destroy -var='aws_profile=CCRubrikPOCTest'
```

Note: run one of the init-state commands first. Do not run plain `terraform init` before choosing local or remote mode.

## GitHub Actions Deployment

For GitHub Actions plan, apply, and destroy instructions, see [.github/workflows/README.md](../../.github/workflows/README.md).

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
terraform -chdir=examples/cc-rubrik-poc-test apply -var='aws_profile=CCRubrikPOCTest' -var='dashboard_allowed_cidrs=["203.0.113.10/32"]'
```

When done testing, remove that access and apply again:

```sh
terraform -chdir=examples/cc-rubrik-poc-test apply -var='aws_profile=CCRubrikPOCTest' -var='dashboard_allowed_cidrs=[]'
```

## Instance Type Variants

To validate a second instance type without editing files:

```sh
terraform -chdir=examples/cc-rubrik-poc-test plan -var='aws_profile=CCRubrikPOCTest' -var='instance_type=t3.medium.search'
terraform -chdir=examples/cc-rubrik-poc-test apply -var='aws_profile=CCRubrikPOCTest' -var='instance_type=t3.medium.search'
```