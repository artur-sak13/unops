resource "aws_kms_key" "key" {
  description = "mattermost webhook url encryption key"
  is_enabled  = true
}

data "aws_kms_ciphertext" "kms_cipher" {
  key_id    = "${aws_kms_key.key.key_id}"
  plaintext = "${var.mattermost_webhook_url}"
}

data "archive_file" "notify_mattermost" {
  type        = "zip"
  source_file = "function/${var.lambda_name}.py"
  output_path = "function/${var.lambda_name}.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "LambdaMattermostExecute"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "lambda_kms" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_kms_policy.arn}"
}

resource "aws_iam_policy" "lambda_kms_policy" {
  name   = "LambdaKMSPolicy"
  policy = "${data.aws_iam_policy_document.lambda_kms_document.json}"
}

data "aws_iam_policy_document" "lambda_kms_document" {
  statement {
    effect = "Allow"

    resources = [
      "${aws_kms_key.key.arn}",
    ]

    actions = [
      "kms:Decrypt",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cwlogs" {
  role       = "${aws_iam_role.lambda_role.name}"
  policy_arn = "${aws_iam_policy.lambda_cwlogs_policy.arn}"
}

resource "aws_iam_policy" "lambda_cwlogs_policy" {
  name   = "LambdaCwlogsPolicy"
  policy = "${data.aws_iam_policy_document.lambda_cwlogs_document.json}"
}

data "aws_iam_policy_document" "lambda_cwlogs_document" {
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:*",
    ]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_lambda_function" "notify_mattermost" {
  filename         = "${data.archive_file.notify_mattermost.output_path}"
  function_name    = "${var.lambda_name}"
  role             = "${aws_iam_role.lambda_mattermost_role.arn}"
  source_code_hash = "${data.archive_file.notify_mattermost.output_base65sha256}"
  runtime          = "python3.7"
  timeout          = 30

  environment {
    variables {
      AWS_REGION             = "${var.region}"
      MATTERMOST_WEBHOOK_URL = "${data.aws_kms_ciphertext.kms_cipher.ciphertext_blob}"
      MATTERMOST_CHANNEL     = "${var.mattermost_channel}"
      MATTERMOST_USERNAME    = "${var.mattermost_username}"
      MATTERMOST_ICONURL     = "${var.mattermost_iconurl}"
    }
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.notify_mattermost.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.custom_event.arn}"
}
