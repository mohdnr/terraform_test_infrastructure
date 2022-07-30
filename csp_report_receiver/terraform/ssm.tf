resource "random_password" "app_key" {
  length           = 48
  special          = true
  override_special = "-="
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "app_key" {
  name  = "/csp_reports/app_key"
  type  = "String"
  value = random_password.app_key.result
}

resource "aws_ssm_parameter" "db_host" {
  name  = "/csp_reports/db_host"
  type  = "String"
  value = aws_rds_cluster.csp_reports.endpoint
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/csp_reports/db_username"
  type  = "String"
  value = aws_rds_cluster.csp_reports.master_username
}

resource "aws_ssm_parameter" "db_database" {
  name  = "/csp_reports/db_database"
  type  = "String"
  value = aws_rds_cluster.csp_reports.database_name
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/csp_reports/db_password"
  type  = "String"
  value = random_password.password.result
}
