provider "aws" {
  profile = "default"
  region = "us-east-1"
}


terraform {
  backend "s3" {
    bucket = "ecscolortestbucket008340"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
