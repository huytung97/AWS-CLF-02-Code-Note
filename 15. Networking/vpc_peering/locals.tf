locals {
  region = "ap-southeast-1"

  vpc_cidr_list    = ["10.0.0.0/16", "10.1.0.0/16"]
  subnet_cidr_list = ["10.0.1.0/24", "10.1.1.0/24"]
}