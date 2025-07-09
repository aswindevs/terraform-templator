terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "my-project-dev-terraform-state"
    key            = "base-infra/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "my-project-dev-terraform-lock"
  }
}

provider "aws" {
  region  = "us-west-2"

  default_tags {
    tags = local.tags
  }
} 
