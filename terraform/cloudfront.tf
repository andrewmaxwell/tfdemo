resource "aws_cloudfront_origin_access_control" "oac" {
  name                 = "my-cloudfront-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior     = "always"
  signing_protocol     = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.frontend_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.frontend_bucket.bucket
    viewer_protocol_policy = "redirect-to-https"
    compress         = true 

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0        # Minimum TTL in seconds (0 allows for immediate invalidation)
    default_ttl = 10       # Default TTL in seconds (set to 10 seconds)
    max_ttl     = 10       # Maximum TTL in seconds (also set to 10 seconds)
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