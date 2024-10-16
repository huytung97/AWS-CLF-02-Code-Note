provider "aws" {
  region = "ap-southeast-1"
}


resource "aws_s3_bucket" "chap_8_clf_02_tung" {
    bucket = "chap-8-clf-02-tung-test"

    tags = {
      "Name" = "Test Bucket Chap 8 - CLF 02"
    }

    force_destroy = true
}

resource "aws_s3_object" "chap_8_clf_02_tung_outer_file" {
  bucket = aws_s3_bucket.chap_8_clf_02_tung.bucket
  key = "file1.txt"

  source = "${path.root}/test_files/file1.txt"
}

resource "aws_s3_object" "chap_8_clf_02_tung_access_dir" {
  bucket = aws_s3_bucket.chap_8_clf_02_tung.bucket
  key = "access/file2.txt"

  source = "${path.root}/test_files/file2.txt"
}


resource "aws_iam_policy" "iam_policy_list_read_s3" {
  name = "iam_policy_list_read_s3"
  path = "/"

  policy = file("${path.root}/policies/list_and_read_bucket.json")
}

resource "aws_iam_role" "iam_role_ec2_list_read_bucket" {
  name = "test_iam_user_chap_8_s3"

  assume_role_policy = file("${path.root}/policies/iam_role_ec2.json")
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_ec2_role_list_users" {
  role = aws_iam_role.iam_role_ec2_list_read_bucket.name
  policy_arn = aws_iam_policy.iam_policy_list_read_s3.arn
}

### EC2
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "sg_test_ec2_chap_8" {
  name        = "secgroup-test-ec2-chap-8"
  description = "Test EC2 SG for chap 8 course udemy"
  vpc_id      = data.aws_vpc.default.id
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_8.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_8.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_instance_profile" "profile_list_read_s3" {
  name = "profile_list_read_s3"
  role = aws_iam_role.iam_role_ec2_list_read_bucket.name
}

resource "aws_instance" "chap-5-ec2" {
  ami           = "ami-012c2e8e24e2ae21d" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name = "my-key-pair-1"

  iam_instance_profile = aws_iam_instance_profile.profile_list_read_s3.name

  vpc_security_group_ids = [aws_security_group.sg_test_ec2_chap_8.id]

  tags = {
    Name = "chap-8-ec2"
  }
}

output "ec2-instance-public-ip" {
  value = aws_instance.chap-5-ec2.public_ip 
}