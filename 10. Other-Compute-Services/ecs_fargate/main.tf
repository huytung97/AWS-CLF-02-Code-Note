provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ecr_repository" "ecr_repo" {
  name = "test-ns/test-repo"
}

data "aws_ecr_image" "filtered_image" {
  repository_name = data.aws_ecr_repository.ecr_repo.name
  image_tag       = "0.1"
}

# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach necessary policies to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

# ECS Task Definition
resource "aws_ecs_task_definition" "ecs_task" {
  family = "my-ecs-task"
  container_definitions = jsonencode([
    {
      name      = "my-container",
      image     = data.aws_ecr_image.filtered_image.image_uri,
      cpu       = 1024,
      memory    = 2048,
      essential = true,
      portMappings = [{
        containerPort = 8000
        hostPort      = 8000
      }]
    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  memory                   = "2048"
  cpu                      = "1024"
}

resource "aws_security_group" "sg_test_ec2_chap_10" {
  name        = "secgroup-test-ec2-chap-10"
  description = "Test EC2 SG for chap 10 course udemy"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_websrv_port_ingress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_10.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_ec2_chap_10.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # All protocols
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.public_subnets.ids
    security_groups = [aws_security_group.sg_test_ec2_chap_10.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group_chap_10.arn
    container_name   = "my-container"
    container_port   = var.server_port
  }

  depends_on = [aws_lb.lb_chap_10]
}

## Load balance
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
  from_port   = 0
  ip_protocol = "-1"
  to_port     = 0
}

resource "aws_lb" "lb_chap_10" {
  name               = "load-balancer-chap-10"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_for_lb.id]
  subnets            = data.aws_subnets.public_subnets.ids
}

resource "aws_lb_target_group" "lb_target_group_chap_10" {
  name     = "lb-target-group-chap-10"
  protocol = "HTTP"
  port     = var.server_port
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "lb_listener_chap_10" {
  load_balancer_arn = aws_lb.lb_chap_10.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group_chap_10.arn
  }
}

output "alb_dns" {
  value = aws_lb.lb_chap_10.dns_name
}