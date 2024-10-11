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
  etag         = filemd5("index.html")
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

resource "aws_dynamodb_table" "click_counter" {
  name           = "click_counter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function" "click_counter" {
  function_name = "click_counter"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "lambda.zip"  # Path to your zipped Lambda function
  source_code_hash = filebase64sha256("lambda.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.click_counter.name
    }
  }
}

# Define the API Gateway resource
resource "aws_apigatewayv2_api" "api" {
  name          = "ClickCounterAPI"
  protocol_type = "HTTP"
}

# Define a route for the API (e.g., /click)
resource "aws_apigatewayv2_route" "click_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /click"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Ensure the CORS settings are in place
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.click_counter.arn
}

# Create a stage (e.g., prod) and deploy the API
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"  # You can also call it "dev" or another name if needed
  auto_deploy = true    # Automatically deploy new changes to this stage
}

# Lambda execution permissions for API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.click_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

# Output the API Gateway Invoke URL (Optional)
output "api_gateway_invoke_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}"
  description = "The invoke URL for the API Gateway"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_dynamodb_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ],
        "Resource": aws_dynamodb_table.click_counter.arn
      }
    ]
  })
}
