resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = var.source_vpc_id
  peer_vpc_id = var.target_vpc_id

  auto_accept = var.auto_accept
}

data "aws_route_table" "vpc_requester_default_route_tbl" {
  filter {
    name   = "vpc-id"
    values = [var.source_vpc_id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

data "aws_route_table" "vpc_target_default_route_tbl" {
  filter {
    name   = "vpc-id"
    values = [var.target_vpc_id]
  }

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_route" "source_vpc_route_tbl_peering" {
  route_table_id            = data.aws_route_table.vpc_requester_default_route_tbl.id
  destination_cidr_block    = var.target_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "target_vpc_route_tbl_peering" {
  route_table_id            = data.aws_route_table.vpc_target_default_route_tbl.id
  destination_cidr_block    = var.source_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}
