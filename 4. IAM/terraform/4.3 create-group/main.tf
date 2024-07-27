provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_iam_group" "test_group_2" {
  name = "test_group_2"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "policy_attach_list_iam" {
  group = aws_iam_group.test_group_2.name
  policy_arn = "arn:aws:iam::444903350037:policy/list_iam_users"
}

resource "aws_iam_user_group_membership" "group_membership_test_group_2" {
  user = "test_user_iam"
  groups = [
    aws_iam_group.test_group_2.name
  ]
}