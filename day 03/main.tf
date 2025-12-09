terraform {

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
      }
    }
}
provider "aws" {
    region = "us-west-2"
}

#create s3 bucket
resource "aws_s3_bucket" "first_demo_bucket" {
  bucket = "my-tf-demo-s3-bucket-01"


  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}