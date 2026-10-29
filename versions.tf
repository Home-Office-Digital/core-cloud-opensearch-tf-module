terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # v5, matching core-cloud-sqs-tf-module. 0.0.2 narrowed this to "~> 6.62",
      # which made the module impossible to use alongside SQS: a v5-only and a
      # v6-only constraint have no overlap, so Terraform cannot select a provider.
      # The module code is unchanged since 0.0.1, which shipped against v5.
      version = "~> 5.40"
    }
  }
  required_version = ">= 1.5.0"
}
