resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "andrewmaxwell-learntf"
}

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

resource "aws_s3_object" "frontend_files" {
  bucket = aws_s3_bucket.frontend_bucket.bucket
  key    = "index.html"
  source = "../client/index.html"
  content_type = "text/html"
  etag         = filemd5("../client/index.html")
}