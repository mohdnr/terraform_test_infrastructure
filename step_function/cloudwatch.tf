resource "aws_cloudwatch_event_rule" "keep_warm" {
  name                = "lambda_warmer"
  schedule_expression = "rate(4 minutes)"
}

resource "aws_cloudwatch_event_target" "this" {
  rule      = aws_cloudwatch_event_rule.keep_warm.name
  target_id = aws_lambda_function.account_management.function_name
  arn       = aws_lambda_function.account_management.arn
  input_transformer {
    input_template = "{\"Records\":[]}"
  }
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.account_management.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.keep_warm.arn
}
