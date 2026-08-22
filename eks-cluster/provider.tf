terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend: stores tfstate in S3 (versioned) and uses DynamoDB for state locking.
  # State locking prevents two people from running apply at the same time and corrupting state.
  # IMPORTANT: the S3 bucket and DynamoDB table must exist BEFORE the first terraform init.
  # Create them manually via AWS Console or CLI:
  #   aws s3api create-bucket --bucket nahla-terraform-state-686893581621 --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
  #   aws dynamodb create-table --table-name terraform-state-lock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-west-2
  backend "s3" {
    bucket         = "nahla-terraform-state-686893581621"
    key            = "eks/us-west-2/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock" # table must have a partition key named "LockID"
    encrypt        = true                   # encrypts the state file at rest in S3
  }
}

provider "aws" {
  region = "us-west-2"
}
