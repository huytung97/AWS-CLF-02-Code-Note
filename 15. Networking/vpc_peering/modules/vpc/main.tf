resource "aws_vpc" "main" {
  tags = var.vpc_tags

  cidr_block = var.vpc_cidr
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {

  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  tags = {
    "Name" = "CLF-02-Chap-15-VPC-Peering-1-public-subnet"
  }
}

data "aws_route_table" "vpc_main_default_route_tbl" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "default_route_tbl_internet" {
  route_table_id         = data.aws_route_table.vpc_main_default_route_tbl.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on             = [aws_internet_gateway.igw]
}
