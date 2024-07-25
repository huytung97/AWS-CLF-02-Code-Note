provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_iam_policy" "iam_policy_list_users" {
  name = "iam_policy_list_users"
  path = "/"

  policy = file("${path.root}/listUserPolicyDocument.json")
}

resource "aws_iam_role" "iam_role_ec2_list_users" {
  name = "EC2_ListUsers_2"

  assume_role_policy = file("${path.root}/policyDocument.json")
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_ec2_role_list_users" {
  role = aws_iam_role.iam_role_ec2_list_users.name
  policy_arn = aws_iam_policy.iam_policy_list_users.arn
}