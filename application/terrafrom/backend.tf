terraform {
  backend "s3" {
    bucket         = "terrafrom-depi-project" 
    key            = "restaurant-app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}