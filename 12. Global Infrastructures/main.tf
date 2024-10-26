provider "aws" {
  region = "ap-southeast-1"
}


data "local_file" "asset_files" {
  for_each = fileset("${path.root}/assets", "*")
  filename = "${path.root}/assets/${each.value}"
}

resource "aws_s3_bucket" "s3_chap_12_cloudfront" {
  bucket        = "clf02-chap12-tung-test"
  force_destroy = true
}

resource "aws_s3_object" "upload_files" {
  for_each = data.local_file.asset_files

  bucket = aws_s3_bucket.s3_chap_12_cloudfront.bucket
  key    = basename(each.key)
  source = each.value.filename
  etag   = each.value.content_md5
}

locals {
  s3_origin_id = "S3_Origin_CLF02_Chap12"
}


resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac_clf02_chap12"
  description                       = "Origin Access Control for S3 bucket access: CLF02 - chap 12"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # CloudFront signs every request
  signing_protocol                  = "sigv4"  # Uses SigV4 for signing requests
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.s3_chap_12_cloudfront.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.s3_chap_12_cloudfront.arn}/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = aws_s3_bucket.s3_chap_12_cloudfront.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled         = true
  is_ipv6_enabled = true
  default_cache_behavior {
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Use CloudFront's default certificate for HTTPS
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


output "asset_filenames" {
  value = [for f in data.local_file.asset_files : f.filename]
}

output "cdn_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}