resource "aws_dynamodb_table" "click_counter" {
  name           = "click_counter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
