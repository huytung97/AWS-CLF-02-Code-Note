
resource "aws_security_group" "public_instance_sg" {
  name        = "clf-02-chap-15-public-sg"
  description = "CLF 02 - Chap 15 - Public instance security group"
  vpc_id      = var.main_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "public_sg_allow_ssh" {
  security_group_id = aws_security_group.public_instance_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "public_sg_allow_all_egress" {
  security_group_id = aws_security_group.public_instance_sg.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "public_instance" {
  ami           = local.ami_id
  instance_type = var.instance_type
  key_name = var.key_pair_name

  vpc_security_group_ids = [aws_security_group.public_instance_sg.id]
  subnet_id = var.public_subnet_id

  associate_public_ip_address = true

  tags = {
    "Name" = "CLF-02-Chap-15-public-instance"
  }
}