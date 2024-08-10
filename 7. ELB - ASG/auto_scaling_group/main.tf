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


resource "aws_launch_template" "launch_template_chap_7" {
  name_prefix   = "launch_template_chap_7"
  image_id      = "ami-0497a974f8d5dcef8" # Update with your AMI ID
  instance_type = "t2.micro"

  key_name = "my-key-pair-1"

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              echo "Hello, World!" > /var/www/html/index.html
              EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_test_ec2_chap_7.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  desired_capacity = 2
  max_size         = 3
  min_size         = 1

  launch_template {
    id      = aws_launch_template.launch_template_chap_7.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.default_subnet.ids

  tag {
    key                 = "Name"
    value               = "chap-7-asg"
    propagate_at_launch = true
  }

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

resource "aws_autoscaling_attachment" "chap_7_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example.id
  lb_target_group_arn    = aws_lb_target_group.lb_target_group_chap_7.arn
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

output "lb_dns_name" {
  value = aws_lb.lb_chap_7.dns_name
}