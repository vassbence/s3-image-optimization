data "aws_iam_policy_document" "assume_lambda_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.original_images.arn}/*",
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.optimized_images.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "s3-image-optimization-lambda-policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}


resource "aws_iam_role" "iam_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_policy.json
  name               = "s3-image-optimization-lambda-role"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "image_optimizer_lambda" {
  filename         = "../dist/image-optimizer-lambda.zip"
  function_name    = "${terraform.workspace}-s3-image-optimization-optimizer"
  role             = aws_iam_role.iam_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("../dist/image-optimizer-lambda.zip")
  memory_size      = 1769 # = 1 vCPU as per https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
  timeout          = 20

  environment {
    variables = {
      OPTIMIZED_IMAGES_BUCKET_NAME = aws_s3_bucket.optimized_images.id
      ORIGINAL_IMAGES_BUCKET_NAME  = aws_s3_bucket.original_images.id
      OPTIMIZED_IMAGES_BUCKET_URL  = aws_s3_bucket.optimized_images.bucket_regional_domain_name
    }
  }
}

resource "aws_lambda_function_url" "image_optimizer_lambda_public_url" {
  function_name      = aws_lambda_function.image_optimizer_lambda.function_name
  authorization_type = "NONE"
}
