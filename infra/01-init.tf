terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.38.0"
    }
  }
}

provider "aws" {
  region = local.region
}

locals {
  name                = "test"
  environment         = "dev"
  region              = "eu-central-1"
  ami                 = "ami-0a5b5c0ea66ec560d"
  instance_type       = "t2.micro"
  cidr                = "10.0.0.0/16"
  availability_zones  = ["${local.region}a", "${local.region}b"]
  private_subnets     = ["10.0.0.0/20", "10.0.16.0/20"]
  public_subnets      = ["10.0.32.0/20", "10.0.64.0/20"]
  key_name            = "mykey"
  key_path            = "~/.aws/pems/mykey.pem"
}