provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_iam_role" "role_ec2_listUsers" {
  name = "EC2_listUsers"
}

resource "aws_security_group" "sg_test_ec2_chap_14" {
  name        = "secgroup-test-ec2-chap-14"
  description = "Test EC2 SG for chap 14 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_14.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_14.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_iam_instance_profile" "profile_list_user_ec2" {
  name = "profile_list_user_ec2"
  role = data.aws_iam_role.role_ec2_listUsers.name
}

resource "aws_instance" "chap_14_ec2" {
  ami           = "ami-012c2e8e24e2ae21d" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name = "my-key-pair-1"

  iam_instance_profile = aws_iam_instance_profile.profile_list_user_ec2.name

  vpc_security_group_ids = [aws_security_group.sg_test_ec2_chap_14.id]

  tags = {
    Name = "chap-14-ec2"
  }
}

resource "aws_sns_topic" "chap_14" {
  name = "sns_topic_chap_1r"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.chap_14.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email_test
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  alarm_description   = "Alarm when CPU utilization exceeds 80%"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.chap_14.arn]

  dimensions = {
    InstanceId = aws_instance.chap_14_ec2.id
  }

  tags = {
    Environment = "production"
  }
}


output "ec2-instance-public-ip" {
  value = aws_instance.chap_14_ec2.public_ip 
}
