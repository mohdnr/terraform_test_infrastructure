module "purge_csp_reports_lambda" {
  source                 = "github.com/cds-snc/terraform-modules?ref=v3.0.5//lambda"
  name                   = "purge_csp_reports"
  billing_tag_value      = var.billing_code
  ecr_arn                = aws_ecr_repository.purge_csp_reports.arn
  enable_lambda_insights = true
  image_uri              = "${aws_ecr_repository.purge_csp_reports.repository_url}:latest"
  memory                 = 512
  timeout                = 300

  vpc = {
    security_group_ids = [aws_security_group.csp_reports.id]
    subnet_ids         = module.vpc.private_subnet_ids
  }

  environment_variables = {
    DB_HOST                 = aws_rds_cluster.csp_reports.endpoint
    DB_USERNAME             = aws_rds_cluster.csp_reports.master_username
    DB_DATABASE             = aws_rds_cluster.csp_reports.database_name
    DB_PASSWORD             = random_password.password.result
    DB_PORT                 = 5432
    POWERTOOLS_SERVICE_NAME = "${var.product_name}"
  }

  policies = [
    data.aws_iam_policy_document.purge_csp_reports_lambda_policies.json,
  ]
}
