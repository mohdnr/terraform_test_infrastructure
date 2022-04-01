resource "aws_sfn_state_machine" "workload_management" {
  name     = "workload-queue"
  role_arn = aws_iam_role.workload_queue.arn

  definition = data.template_file.workload_queue.rendered

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "template_file" "workload_queue" {
  template = file("state-machines/workload-queue.json")
  vars = {
    account_lambda  = aws_lambda_function.account_management.function_name
    workflow_lambda = aws_lambda_function.workflow_management.function_name
  }
}
