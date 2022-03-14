resource "aws_secretsmanager_secret" "environment_variables" {
  name = "environment_variables"

  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.environment_variables.id
}
