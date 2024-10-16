provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_dynamodb_table" "test_table" {
  name = "test_tables"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  # partition key
  hash_key = "Id"
  # sort key
  range_key = "GameTitle"

  attribute {
    name = "Id"
    type = "S"
  }
  attribute {
    name = "GameTitle"
    type = "S"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }
}