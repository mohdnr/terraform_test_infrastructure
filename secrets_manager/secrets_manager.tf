resource "random_string" "random_suffix" {
  length  = 8
  special = false
}

resource "aws_secretsmanager_secret" "environment_variables" {
  name = "environment_variables_${random_string.random_suffix.result}"
  tags = {
    CostCentre = var.billing_code
    Terraform  = true
  }
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.environment_variables.id
}
