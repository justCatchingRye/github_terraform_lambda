terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"   # or your preferred version
    }
  }
}

provider "aws" {
  region = "eu-west-2"   # change to your actual region
  # access_key and secret_key are pulled from env vars (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
}
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam-for-lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda.py"
  output_path = "lambda_function_src.zip"
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function_src.zip"
  function_name    = "python_terraform_lambda"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.13"
  handler = "lambda_handler"
}