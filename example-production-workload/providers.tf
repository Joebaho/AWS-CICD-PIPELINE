terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "baho-backup-bucket"
    key            = "Codepipeline-backup/example-prod-workload/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "full-devops-table"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-west-2"
}