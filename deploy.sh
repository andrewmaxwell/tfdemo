#!/bin/bash

set -e

LAMBDA_FILE="index.js"
ZIP_FILE="lambda.zip"

echo "Zipping the Lambda function..."
zip -r $ZIP_FILE $LAMBDA_FILE node_modules

echo "Running Terraform apply..."
terraform apply -auto-approve

echo "Deployment complete!"
