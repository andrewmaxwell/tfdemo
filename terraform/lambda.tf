resource "aws_lambda_function" "click_counter" {
  function_name = "click_counter"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = "../lambda.zip"  # Path to your zipped Lambda function
  source_code_hash = filebase64sha256("../lambda.zip")
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.click_counter.name
    }
  }
}