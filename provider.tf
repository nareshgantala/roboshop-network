terraform {
  backend "s3" {
    region       = "us-east-1"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}



provider "aws" {
  region = "us-east-1"
}

