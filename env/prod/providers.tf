provider "aws" {
  region = local.aws_region
}

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
  backend "s3" {
    bucket = "mortgage-xpert-tfstate-446311000231"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}
