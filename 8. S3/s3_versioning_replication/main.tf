provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "clf_02_chap_8_versioning" {
  bucket = "tung-clf-02-chap-8-versioning"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "clf_02_chap_8_versioning_enable" {
  bucket = aws_s3_bucket.clf_02_chap_8_versioning.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "clf_02_chap_8_destination" {
  bucket = "tung-clf-02-chap-8-destination"
  force_destroy = true
}