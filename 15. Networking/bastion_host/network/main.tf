resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = var.vpc_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {

  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.az[0]

  tags = {
    "Name" = "CLF-02-Chap-15-bastion-host-public-subnet"
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
  route_table_id = data.aws_route_table.vpc_main_default_route_tbl.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
  depends_on = [ aws_internet_gateway.igw ]
}

## Setup Private subnets
### Setup Nat gateway
resource "aws_eip" "eip_nat_gateway" {
  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_nat_gateway" "nat_for_priv_sbns" {
  subnet_id = aws_subnet.public_subnet.id
  allocation_id = aws_eip.eip_nat_gateway.id

  depends_on = [ aws_internet_gateway.igw ]

  tags = {
    "Name" = "CLF-02-Chap-15-bastion-host-lab"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = { for idx, cidr in var.private_subnets_cidr : idx => cidr }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.az[each.key % length(var.az)]

  tags = {
    "Name" = "CLF-02-Chap-15-bastion-host-private-${each.key + 1}"
  }
}

resource "aws_route_table" "route_tbls_private_network" {
  for_each = aws_subnet.private_subnets

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private Route Table for ${each.key}"
  }
}

resource "aws_route" "private_network_route_nat" {
  for_each = aws_route_table.route_tbls_private_network

  route_table_id = each.value.id
  nat_gateway_id = aws_nat_gateway.nat_for_priv_sbns.id
  destination_cidr_block = "0.0.0.0/0"
}

# Associate each subnet with its route table
resource "aws_route_table_association" "route_table_association" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_tbls_private_network[each.key].id
}