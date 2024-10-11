output "api_gateway_invoke_url" {
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.prod.name}"
  description = "The invoke URL for the API Gateway"
}