terraform {
	  required_providers {
	    aws = {
	      source  = "hashicorp/aws"
	      version = "~> 5.0.0"
	    }
	  }
	}

	provider "aws" {
	  profile                  = ""
	  shared_credentials_files = ["~/.aws/credentials"]
	  region                   = var.region
	}