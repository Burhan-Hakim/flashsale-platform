terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # bucket details get passed in at init time
  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project = "flashsale-platform"
      Purpose = "portfolio-lab"
    }
  }
}
