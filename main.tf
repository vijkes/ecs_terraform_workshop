provider "aws" {
  profile = "default"

}


terraform {
  backend "s3" {
    bucket = "ecscolortestbucket008340"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}
