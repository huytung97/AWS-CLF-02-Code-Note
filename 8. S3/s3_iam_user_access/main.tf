provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {}

# Create an IAM user
resource "aws_iam_user" "clf_02_chap_8_s3_iam_user" {
  name = "clf-02-chap-8-s3"
  path = "/"
}

# Create a login profile for the user, which includes a password
resource "aws_iam_user_login_profile" "clf_02_chap_8_s3_iam_user_profile" {
  user = aws_iam_user.clf_02_chap_8_s3_iam_user.name
  # password = random_password.iam_password.result

  # Require the user to change their password upon first login
  password_reset_required = true
}

resource "aws_iam_policy" "self_change_password" {
  name = "self-change-password-chap-8-clf-02"
  path = "/"

  policy = templatefile("${path.root}/policies/change_password.json", {
    "account_id" : data.aws_caller_identity.current.account_id,
    "iam_user_name" : aws_iam_user.clf_02_chap_8_s3_iam_user.name
  })
}

resource "aws_iam_user_policy_attachment" "change_password_clf_02_chap_8" {
  policy_arn = aws_iam_policy.self_change_password.arn
  user       = aws_iam_user.clf_02_chap_8_s3_iam_user.name
}

resource "aws_iam_policy" "clf_02_chap_8_s3_access_iam_user" {
  name = "clf-02-chap-8-s3-access-iam-user"
  path = "/"

  policy = file("${path.root}/policies/access_s3.json")
}

resource "aws_iam_user_policy_attachment" "access_s3_clf_02_chap_8" {
  policy_arn = aws_iam_policy.clf_02_chap_8_s3_access_iam_user.arn
  user       = aws_iam_user.clf_02_chap_8_s3_iam_user.name
}


## Create S3
resource "aws_s3_bucket" "clf_02_chap_8_s3_iam_user" {
  bucket = "tung-clf-02-chap-8-s3-iam-user"

  tags = {
    Name = "clf_02_chap_8_s3_iam_user"
  }

  force_destroy = true
}

resource "aws_s3_object" "clf_02_chap_8_s3_outer_file" {
  bucket = aws_s3_bucket.clf_02_chap_8_s3_iam_user.bucket
  key = "file1.txt"

  source = "${path.root}/test_files/file1.txt"
}

resource "aws_s3_object" "clf_02_chap_8_s3_access_dir" {
  bucket = aws_s3_bucket.clf_02_chap_8_s3_iam_user.bucket
  key = "access/file2.txt"

  source = "${path.root}/test_files/file2.txt"
}

resource "aws_s3_object" "clf_02_chap_8_s3_access_subdir" {
  bucket = aws_s3_bucket.clf_02_chap_8_s3_iam_user.bucket
  key = "access/subdir/file1.txt"

  source = "${path.root}/test_files/file1.txt"
}

resource "aws_s3_object" "clf_02_chap_8_s3_secret_dir" {
  bucket = aws_s3_bucket.clf_02_chap_8_s3_iam_user.bucket
  key = "secret/file3.txt"

  source = "${path.root}/test_files/file3.txt"
}

# Output the IAM username
output "iam_user_name" {
  description = "The IAM user's name."
  value       = aws_iam_user.clf_02_chap_8_s3_iam_user.name
}


# Output the IAM user's initial password (sensitive output)
output "iam_user_password" {
  description = "The initial password for the IAM user. The user must change the password upon first login."
  value       = aws_iam_user_login_profile.clf_02_chap_8_s3_iam_user_profile.password
  sensitive   = true # Hide the output in the CLI
}