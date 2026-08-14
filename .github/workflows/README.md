# Example OpenSearchTest Workflows

This directory contains the GitHub Actions workflows for deploying the `examples/cc-rubrik-poc-test` Terraform root module. Use [examples/cc-rubrik-poc-test/README.md](../../examples/cc-rubrik-poc-test/README.md) for local or AWS SSO deployment instructions.

## Prerequisites

Before running a workflow, make sure that:

- The S3 state bucket already exists and the configured state key is correct.
- The GitHub OIDC role exists in the target AWS account and permits the required Terraform and OpenSearch actions.
- Repository secret `AWS_ACCOUNT_ID_RUBRIK_POC_TEST` contains the target 12-digit AWS account ID.
- Repository secret `AWS_ROLE_TO_ASSUME_RUBRIK_POC_TEST` contains only the OIDC IAM role name, for example `GitHubActionsTerraformOpenSearch`. Do not provide a full role ARN; the shared Terraform action builds it from both secrets.
- The workflow runs from the branch specified by `apply_branch` when applying or destroying resources.

The state bucket and OIDC role can be provisioned with [examples/state-bootstrap/README.md](../../examples/state-bootstrap/README.md).

## Workflow Order

1. Run the plan workflow and review its output.
2. Run or allow the apply workflow to run after a successful plan.
3. Run the destroy workflow only when the test deployment is no longer required.

All workflows use remote S3 state. Use the same `state_bucket`, `state_key`, and optional `state_dynamodb_table` for every operation against the same deployment.

## Plan

Workflow: [example-cc-rubrik-poc-test-plan.yaml](example-cc-rubrik-poc-test-plan.yaml)

The plan workflow runs when code is pushed to `feature/CCL-10788-openseach-module`, or it can be started manually from the GitHub Actions page. Both paths use the repository secrets `AWS_ACCOUNT_ID_RUBRIK_POC_TEST` and `AWS_ROLE_TO_ASSUME_RUBRIK_POC_TEST`.

For a manual run, select **Example OpenSearchTest Plan**, choose **Run workflow**, and provide the inputs below. The defaults describe the current Rubrik PoC deployment.

| Input | Default | Purpose |
|---|---|---|
| `working_directory` | `./examples/cc-rubrik-poc-test` | Terraform root module directory |
| `aws_region` | `eu-west-2` | AWS deployment region |
| `state_bucket` | `cc-rubrik-poc-test-tfstate-opensearch` | S3 state bucket |
| `state_key` | `opensearch/example/terraform.tfstate` | S3 state object key |
| `state_dynamodb_table` | empty | Optional DynamoDB lock table |

Review the Terraform plan in the workflow logs before proceeding to apply.

## Apply

Workflow: [example-cc-rubrik-poc-test-apply.yaml](example-cc-rubrik-poc-test-apply.yaml)

The apply workflow has two paths:

- It runs automatically after a successful **Example OpenSearchTest Plan** workflow from `feature/CCL-10788-openseach-module`.
- It can be started manually from the GitHub Actions page.

For a manual apply, select **Example OpenSearchTest Apply**, choose the branch named by `apply_branch`, and set `confirm_apply` to `APPLY`. Provide the same Terraform, region, and state values used for the plan, plus:

| Input | Default | Purpose |
|---|---|---|
| `apply_branch` | `feature/CCL-10788-openseach-module` | Only branch permitted to run the manual apply |
| `confirm_apply` | empty | Must be exactly `APPLY` |

The workflow plans again before it applies. A manual run fails its safety check when the selected branch does not match `apply_branch` or the confirmation is not exact.

## Destroy

Workflow: [example-cc-rubrik-poc-test-destroy.yaml](example-cc-rubrik-poc-test-destroy.yaml)

Destroy is manual only. Select **Example OpenSearchTest Destroy**, choose the branch named by `apply_branch`, provide the same shared values used for apply, and set `confirm_destroy` to `DESTROY`.

| Input | Default | Purpose |
|---|---|---|
| `apply_branch` | `feature/CCL-10788-openseach-module` | Only branch permitted to run destroy |
| `confirm_destroy` | empty | Must be exactly `DESTROY` |

The workflow runs `terraform destroy -auto-approve -input=false`. Verify that the state inputs point to the intended test deployment before confirming. The workflow fails its safety check when the selected branch does not match `apply_branch` or the confirmation is not exact.