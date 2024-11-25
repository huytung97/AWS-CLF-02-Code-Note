provider "aws" {
  region = local.region
}

module "vpc" {
  count = length(local.vpc_cidr_list)

  source = "./modules/vpc"
  vpc_tags = {
    "Name" = "CLF-02-Chap-15-VPC-Peering-network-${count.index + 1}"
  }

  vpc_cidr           = local.vpc_cidr_list[count.index]
  public_subnet_cidr = local.vpc_cidr_list[count.index]
}

module "ec2" {
  # each subnet / vpc has 1 instance for demo purpose
  count  = length(local.vpc_cidr_list)
  source = "./modules/ec2"

  key_pair_name    = var.ec2_key_pair_name
  main_vpc_id      = module.vpc[count.index].vpc_id
  public_subnet_id = module.vpc[count.index].public_subnet_id
}

module "vpc_peering" {
  source = "./modules/vpc_peering"

  source_vpc_id   = module.vpc[0].vpc_id
  source_vpc_cidr = module.vpc[0].vpc_cidr

  target_vpc_cidr = module.vpc[1].vpc_cidr
  target_vpc_id   = module.vpc[1].vpc_id
}