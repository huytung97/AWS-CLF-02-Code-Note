provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "clf_02_chap_8_versioning" {
  bucket        = "tung-clf-02-chap-8-versioning"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "clf_02_chap_8_versioning_enable" {
  bucket = aws_s3_bucket.clf_02_chap_8_versioning.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "clf_02_chap_8_destination" {
  bucket        = "tung-clf-02-chap-8-destination"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "clf_02_chap_8_versioning_enable_destination" {
  bucket = aws_s3_bucket.clf_02_chap_8_destination.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

# Create an IAM role for S3 replication
resource "aws_iam_role" "s3_replication_role" {
  name = "s3-replication-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "s3.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# Attach the S3 replication policy to the IAM role
resource "aws_iam_policy" "s3_replication_policy" {
  name        = "s3-replication-policy"
  description = "Policy to allow S3 replication"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "${aws_s3_bucket.clf_02_chap_8_versioning.arn}",
          "${aws_s3_bucket.clf_02_chap_8_versioning.arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ],
        "Resource" : [
          "${aws_s3_bucket.clf_02_chap_8_destination.arn}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "attach_replication_policy" {
  role       = aws_iam_role.s3_replication_role.name
  policy_arn = aws_iam_policy.s3_replication_policy.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket     = aws_s3_bucket.clf_02_chap_8_versioning.bucket
  depends_on = [aws_s3_bucket_versioning.clf_02_chap_8_versioning_enable]

  role = aws_iam_role.s3_replication_role.arn

  rule {
    id     = "replication-rule-1"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.clf_02_chap_8_destination.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}