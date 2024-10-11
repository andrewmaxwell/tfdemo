#!/bin/bash

set -e

FOLDER_NAME="lambda"
ZIP_FILE="lambda.zip"

echo "Zipping the Lambda function..."
if [ -f $ZIP_FILE ]; then
    rm $ZIP_FILE
    echo "Existing '$ZIP_FILE' has been deleted."
fi
cd $FOLDER_NAME
zip -r ../$ZIP_FILE ./*
cd ..

echo "Running Terraform apply..."
cd terraform
terraform apply -auto-approve

echo "Deployment complete!"
