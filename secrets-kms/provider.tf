terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Separate state from eks-cluster/, same bucket + lock table, different key.
  # This is deliberate: `terraform destroy` in eks-cluster/ never touches this
  # state, so the KMS key survives cluster rebuilds and .sops.yaml never goes
  # stale. See secrets-kms/README.md.
  backend "s3" {
    bucket         = "nahla-terraform-state-686893581621"
    key            = "secrets-kms/us-west-2/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}
