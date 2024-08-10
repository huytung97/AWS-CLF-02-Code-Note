provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "availability-zone"
    values = ["ap-southeast-1a", "ap-southeast-1b"]
  }
}

resource "aws_security_group" "sg_test_ec2_chap_7" {
  name        = "secgroup-test-ec2-chap-7"
  description = "Test EC2 SG for chap 7 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_7.id

  cidr_ipv4   = "118.70.98.129/32"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_7.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_7.id
  from_port         = -1
  to_port           = -1
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "chap-7-ec2" {
  count         = 3
  ami           = "ami-0497a974f8d5dcef8" # Replace with your desired AMI
  instance_type = "t2.micro"
  key_name      = "my-key-pair-1"

  vpc_security_group_ids = [aws_security_group.sg_test_ec2_chap_7.id]

  tags = {
    Name = "chap-7-ec2"
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "<h1> Hello world $(hostname -f) </h1>" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "lb_target_group_chap_7" {
  name     = "lb-target-group-chap-7"
  protocol = "HTTP"
  port     = var.server_port
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "lb_target_group_attachment_chap_7" {
  for_each = {
    for k, v in aws_instance.chap-7-ec2 :
    k => v
  }

  target_group_arn = aws_lb_target_group.lb_target_group_chap_7.arn
  target_id        = each.value.id
  port             = var.server_port
}

## Load Balancer & Security group for LB
resource "aws_security_group" "sg_for_lb" {
  name        = "sg_for_lb"
  description = "Security group for load balancer: allow http"

  vpc_id = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "sg_in_allow_http_for_lb" {
  security_group_id = aws_security_group.sg_for_lb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "sg_out_allow_http_for_lb" {
  security_group_id = aws_security_group.sg_for_lb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_lb" "lb_chap_7" {
  name               = "load-balancer-chap-7"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_for_lb.id]
  subnets = data.aws_subnets.default_subnet.ids
}

resource "aws_lb_listener" "lb_listener_chap_7" {
  load_balancer_arn = aws_lb.lb_chap_7.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_chap_7.arn
  }
}

output "ec2_global_ips" {
  value = [for instance in aws_instance.chap-7-ec2 : instance.public_ip]
}

output "subnet_information" {
  value = data.aws_subnets.default_subnet.ids
}

output "lb_dns_name" {
  value = aws_lb.lb_chap_7.dns_name
}