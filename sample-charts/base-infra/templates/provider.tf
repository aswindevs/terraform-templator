terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"

  backend "s3" {
    bucket         = "{{ .project.name }}-{{ .project.environment }}-terraform-state"
    key            = "base-infra/terraform.tfstate"
    region         = "{{ .project.region }}"
    encrypt        = true
    dynamodb_table = "{{ .project.name }}-{{ .project.environment }}-terraform-locks"
  }
}

provider "aws" {
  region  = "{{ .project.region }}"
  profile = "{{ .provider.aws.profile }}"

  default_tags {
    tags = local.tags
  }
} 
