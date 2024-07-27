provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {}


resource "aws_iam_user" "test_iam_user" {
  name = "test_iam_user_2"
}

resource "aws_iam_user_policy_attachment" "attach_policy_test_iam_user_list_iam_users" {
  user = aws_iam_user.test_iam_user.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/list_iam_users"
}