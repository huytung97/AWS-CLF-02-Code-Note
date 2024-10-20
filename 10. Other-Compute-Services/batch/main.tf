provider "aws" {
  region = "ap-southeast-1"
}

data "aws_ecr_repository" "ecr_repo" {
  name = "test-ns/test-batch-job"
}

data "aws_ecr_image" "filtered_image" {
  repository_name = data.aws_ecr_repository.ecr_repo.name
  image_tag       = "0.3"
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the public subnets in the default VPC
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

# Create an IAM role for AWS Batch service
resource "aws_iam_role" "batch_service_role" {
  name = "aws-batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AWS managed policy for Batch service role
resource "aws_iam_role_policy_attachment" "batch_service_role_policy" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# Create an IAM role for ECS tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-2"

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

# Attach policies for ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create the AWS Batch Compute Environment
resource "aws_batch_compute_environment" "fargate_compute_env" {
  compute_environment_name = "fargate-compute-environment"
  type                     = "MANAGED"

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 256
    subnets            = data.aws_subnets.public_subnets.ids
    security_group_ids = ["sg-0d2e99981e2d9904e"]
  }

  service_role = aws_iam_role.batch_service_role.arn
}

# Create the AWS Batch Job Queue
resource "aws_batch_job_queue" "job_queue" {
  name     = "fargate-job-queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.fargate_compute_env.arn
  }
}

# Create the AWS Batch Job Definition
resource "aws_batch_job_definition" "job_definition" {
  name = "fargate-job-definition"
  type = "container"

  container_properties = jsonencode({
    image = data.aws_ecr_image.filtered_image.image_uri
    resourceRequirements = [
      {
        type  = "VCPU"
        value = "1"
      },
      {
        type  = "MEMORY"
        value = "2048"
      }
    ]
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    networkConfiguration = {
      assignPublicIp = "ENABLED" # Ensures the job has a public IP
    }
  })

  platform_capabilities = ["FARGATE"]
}