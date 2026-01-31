terraform {
  backend "s3" {
    bucket  = "kcee-dev-tf"
    region  = "eu-central-1"
    key     = "tetris-project/terraform.tfstate"
    encrypt = true
  }
  required_version = ">=1.6.6"
  required_providers {
    aws = {
      version = ">= 5.49.0"
      source  = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}