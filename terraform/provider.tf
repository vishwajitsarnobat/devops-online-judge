terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Terraform state is stored remotely in S3 so it survives laptop changes
  # and can be shared across team members.
  # Run scripts/setup-s3-backend.sh ONCE before the first `terraform init`.
  backend "s3" {
    bucket = "online-judge-tfstate"
    key    = "infra/terraform.tfstate"
    region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region
}
