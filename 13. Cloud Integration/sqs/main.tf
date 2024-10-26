provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_sqs_queue" "terraform_queue" {
  name                      = "sqs_chap_13_clf_02"
  delay_seconds             = local.sqs_delay
  max_message_size          = local.sqs_max_message_size
  message_retention_seconds = local.message_retention_seconds
  receive_wait_time_seconds = local.receive_wait_time_seconds
}