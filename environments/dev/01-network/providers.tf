###############################################################################
# Layer 01-network - Providers
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "lab-aws-terraform-state-361183471902"
    key            = "environments/dev/01-network/terraform.tfstate"
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
      Layer       = "01-network"
    }
  }
}
