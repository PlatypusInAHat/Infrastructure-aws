###############################################################################
# Layer 04-data - Providers
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "lab-aws-terraform-state-ACCOUNT_ID"
    key            = "environments/dev/04-data/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "lab-aws-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Layer       = "04-data"
    }
  }
}
