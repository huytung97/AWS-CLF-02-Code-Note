resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags       = var.vpc_tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    "Name" = "CLF-02-Chap-15-nacl-sg-subnet"
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

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id
}

# Create ingress rules for the NACL
resource "aws_network_acl_rule" "ingress_http" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp" # TCP
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Create egress rules for the NACL
resource "aws_network_acl_rule" "egress_all" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 105
  egress         = true
  protocol       = "tcp" # TCP
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "egress_ping" {
  network_acl_id = aws_network_acl.main.id
  rule_number    = 110
  egress         = true
  protocol       = "1" # ICMP (ping)
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}

# Associate the NACL with the subnet
resource "aws_network_acl_association" "main" {
  subnet_id      = aws_subnet.main_subnet.id
  network_acl_id = aws_network_acl.main.id
}