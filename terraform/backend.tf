terraform {
  backend "s3" {
    bucket = "kodi-eks-lab-tfstate-bucket"
    key    = "eks/terraform.tfstate"
    region = "ap-southeast-1"
  }
}


