provider "aws" {
  region = "ap-southeast-1"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "my_subnet_group" {
  name       = "my-subnet-group"
  subnet_ids = slice(data.aws_subnets.default_vpc_subnets.ids, 0, 2)
}

resource "aws_security_group" "sg_test_rds_chap_9" {
  name        = "secgroup-test-ec2-chap-5"
  description = "Test RDS SG for chap 9 course udemy: MySQL"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress" {
  security_group_id = aws_security_group.sg_test_rds_chap_9.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 3306
  ip_protocol = "tcp"
  to_port     = 3306
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.sg_test_rds_chap_9.id
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_instance" "rds_mysql" {
  identifier              = "my-mysql-db"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.37"
  instance_class          = "db.t3.micro" # Adjust instance size as needed
  username                = var.db_username
  password                = var.db_password
  publicly_accessible     = true # This opens the connection publicly
  skip_final_snapshot     = true
  multi_az                = false
  backup_retention_period = 7
  vpc_security_group_ids  = [aws_security_group.sg_test_rds_chap_9.id]
  db_subnet_group_name    = aws_db_subnet_group.my_subnet_group.name

  # Optional, Adjust based on your requirements
  backup_window      = "03:00-04:00"
  maintenance_window = "Mon:00:00-Mon:03:00"
}

output "rds_endpoint" {
  value = aws_db_instance.rds_mysql.endpoint
}