# Workflows

CI workflows for this child module. There are no deployment workflows here: this repository publishes a Terraform module and does not own a deployable root configuration or any AWS state.

| Workflow | Trigger | Purpose |
|---|---|---|
| [pull-request-sast.yaml](pull-request-sast.yaml) | pull request, push to `main`, `workflow_call` | `terraform init`, `test`, `validate`, `fmt`, TFLint, SonarQube, and Checkov |
| [pull-request-semver-label-check.yaml](pull-request-semver-label-check.yaml) | pull request against `main` | Confirms the PR carries exactly one of `major`, `minor`, or `patch` and calculates the next version |
| [pull-request-semver-tag-merge.yaml](pull-request-semver-tag-merge.yaml) | pull request merged into `main` | Tags the repository with the calculated SemVer value |

## SemVer Labels

Apply one of `major`, `minor`, or `patch` to every PR targeting `main`. Applying more than one fails the check. `patch` is used when no label is present. Add `skip-release` to bypass both SemVer workflows for changes that should not produce a tag.

## Required Secrets

`pull-request-sast.yaml` needs `SONAR_TOKEN` and `SONAR_HOST_URL`, either as repository secrets or passed in by a calling workflow as `sonar_token` and `sonar_host_url`.
