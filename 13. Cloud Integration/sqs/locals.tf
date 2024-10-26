locals {
  sqs_delay                 = 0
  sqs_max_message_size      = 2048 # 2KB
  receive_wait_time_seconds = 0
  message_retention_seconds = 4 * 24 * 60 * 60
}