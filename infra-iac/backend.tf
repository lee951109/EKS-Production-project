terraform {
  backend "s3" {
    bucket         = "eks-production-jihyun-terraform-state"
    key            = "eks/production/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}