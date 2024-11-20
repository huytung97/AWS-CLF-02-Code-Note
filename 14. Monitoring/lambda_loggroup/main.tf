provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambdaExecutionRole" {
  name               = "lambdaExecutionRole_Chap_14_CLF_02"
  assume_role_policy = file("${path.root}/policyDocuments/role.json")
}

resource "aws_cloudwatch_log_group" "lambda_chap_14" {
  name              = "/aws/lambda/chap14_CLF02_Lambda"
  retention_in_days = 7
}

resource "aws_iam_policy" "exec_lambda_chap_14_clf_02" {
  name = "exec_lambda_chap_14_clf_02"
  path = "/"

  policy = templatefile(
    "${path.root}/policyDocuments/lambdaExecutionPolicy.json", {
      "region" : local.region,
      "acc_id" : data.aws_caller_identity.current.account_id,
      "log_group_name" : aws_cloudwatch_log_group.lambda_chap_14.name
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy_to_ec2_role_list_users" {
  role       = aws_iam_role.lambdaExecutionRole.name
  policy_arn = aws_iam_policy.exec_lambda_chap_14_clf_02.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/scripts"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "testFunction_CLF02_Chap14" {
  function_name = "testFunction-CLF02-Chap14"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambdaExecutionRole.arn
  filename      = data.archive_file.lambda_zip.output_path

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda_chap_14.name
  }
}

resource "aws_cloudwatch_event_rule" "clf02_chap_14" {
  name                = "CLF-02-Chap_14"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "clf02_chap_14_target" {
  rule      = aws_cloudwatch_event_rule.clf02_chap_14.name
  target_id = "lambda"
  arn       = aws_lambda_function.testFunction_CLF02_Chap14.arn

  input_transformer {
    input_paths = {
      timestamp = "$.time"
    }

    input_template = <<TEMPLATE
{
  "message": "Hello from EventBridge!",
  "timestamp": <timestamp>
}
TEMPLATE
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.testFunction_CLF02_Chap14.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.clf02_chap_14.arn
}