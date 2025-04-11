terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "{{ .locals.name }}-{{ .locals.environment }}-terraform-state"
    key            = "base-infra/terraform.tfstate"
    region         = "{{ .locals.region }}"
    encrypt        = true
    dynamodb_table = "{{ .locals.name }}-{{ .locals.environment }}-terraform-lock"
  }
}

provider "aws" {
  region  = "{{ .locals.region }}"

  default_tags {
    tags = local.tags
  }
} 
