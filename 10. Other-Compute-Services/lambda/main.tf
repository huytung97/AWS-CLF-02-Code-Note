provider "aws" {
  region = "ap-southeast-1"
}

# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetching public subnets from the default VPC
data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "my-lambda1"
  description   = "My awesome lambda function"
  handler       = "index.handler"
  runtime       = "python3.12"

  source_path = "${path.root}/src/lambda-function1"

  tags = {
    Name = "my-lambda1"
  }
}

resource "aws_security_group" "chap-10-alb-sg" {
  name        = "secgroup-test-ec2-chap-10-lambda"
  description = "Test EC2 SG for chap 10 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_websrv_port_ingress" {
  security_group_id = aws_security_group.chap-10-alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.chap-10-alb-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols
}

resource "aws_lb" "my_alb" {
  name               = "my-lambda-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chap-10-alb-sg.id]
  subnets            = data.aws_subnets.public_subnets.ids  # Add your VPC subnets here
}

resource "aws_lb_target_group" "lambda_tg" {
  name     = "lambda-target-group"
  target_type = "lambda"
}

resource "aws_lambda_permission" "allow_alb_invoke" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function.lambda_function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda_tg.arn
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.lambda_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.lambda_tg.arn
  target_id        = module.lambda_function.lambda_function_arn
  depends_on       = [aws_lambda_permission.allow_alb_invoke]
}

output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}