provider "aws" {
  region = local.region
}

data "aws_availability_zones" "az" {
  state = "available"
}

module "network" {
  source = "./network"

  vpc_cidr_block = "10.0.0.0/16"
  vpc_tags = {
    "Name" = "CLF-02-chap-15"
  }

  az = data.aws_availability_zones.az.names
  public_subnet_cidr = "10.0.1.0/24"
}

module "ec2" {
  source = "./ec2"
  main_vpc_id = module.network.main_vpc_id
  key_pair_name = var.ec2_key_pair_name

  public_subnet_id = module.network.public_subnet_id
}
