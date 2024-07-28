provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_iam_role" "role_ec2_listUsers" {
  name = "EC2_listUsers"
}

resource "aws_security_group" "sg_test_ec2_chap_6" {
  name        = "secgroup-test-ec2-chap-6"
  description = "Test EC2 SG for chap 6 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_6.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_6.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "sg_for_efs_mount_target" {
  name        = "secgroup-efs-chap-6"
  description = "Security group for EFS Mount Target - chap 6"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_mount_point_target" {
  security_group_id = aws_security_group.sg_for_efs_mount_target.id
  from_port = 2049
  to_port = 2049
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.sg_test_ec2_chap_6.id
}

resource "aws_iam_instance_profile" "profile_list_user_ec2" {
  name = "profile_list_user_ec2"
  role = data.aws_iam_role.role_ec2_listUsers.name
}

resource "aws_instance" "chap-6-ec2" {
  ami           = "ami-012c2e8e24e2ae21d" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name = "my-key-pair-1"
  availability_zone = local.availability_zone

  iam_instance_profile = aws_iam_instance_profile.profile_list_user_ec2.name

  vpc_security_group_ids = [aws_security_group.sg_test_ec2_chap_6.id]

  tags = {
    Name = "chap-6-ec2"
  }
}

resource "aws_efs_file_system" "efs_test_chap_6" {
  availability_zone_name = local.availability_zone

  tags = {
    Name = "EFS Chap 6"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_chap_6" {
  file_system_id = aws_efs_file_system.efs_test_chap_6.id
  subnet_id = aws_instance.chap-6-ec2.subnet_id
  security_groups = [
    aws_security_group.sg_for_efs_mount_target.id
  ]
}
