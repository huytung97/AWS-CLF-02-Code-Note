provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_sns_topic" "chap_13" {
  name = "sns_topic_chap_13"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.chap_13.arn
  protocol  = "email"
  endpoint  = var.sns_subscription_email_test
}