terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}
