provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_iam_role" "role_ec2_listUsers" {
  name = "EC2_listUsers"
}

resource "aws_security_group" "sg_test_ec2_chap_5" {
  name        = "secgroup-test-ec2-chap-5"
  description = "Test EC2 SG for chap 5 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_5.id

  cidr_ipv4   = "42.113.60.172/32"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_5.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_instance_profile" "profile_list_user_ec2" {
  name = "profile_list_user_ec2"
  role = data.aws_iam_role.role_ec2_listUsers.name
}

resource "aws_instance" "chap-5-ec2" {
  ami           = "ami-012c2e8e24e2ae21d" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name = "my-key-pair-1"

  iam_instance_profile = aws_iam_instance_profile.profile_list_user_ec2.name

  vpc_security_group_ids = [aws_security_group.sg_test_ec2_chap_5.id]

  tags = {
    Name = "chap-5-ec2"
  }
}

output "ec2-instance-public-ip" {
  value = aws_instance.chap-5-ec2.public_ip 
}
