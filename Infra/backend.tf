terraform {
  backend "s3" {
    bucket = "dodam-terraform-backend"
    key    = "terraform-backend/terraform.tfstate"
    region = "ap-northeast-2"
  }
}