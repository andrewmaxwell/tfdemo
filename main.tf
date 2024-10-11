provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "andrewmaxwell-learntf"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "cloudfront.amazonaws.com"
        },
        "Action": "s3:GetObject",
        "Resource": "${aws_s3_bucket.frontend_bucket.arn}/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                 = "my-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior     = "always"
  signing_protocol     = "sigv4"
}


resource "aws_s3_object" "frontend_files" {
  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = "index.html"
  source = "index.html"
  content_type = "text/html"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.bucket

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled      = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.bucket
    viewer_protocol_policy = "redirect-to-https"
    compress         = true 

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
      headers = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"] 
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}
