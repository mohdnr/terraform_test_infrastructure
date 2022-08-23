locals {
  cidr_block = "10.0.0.0/16"
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v3.0.5//vpc"
  name   = var.product_name

  high_availability  = true
  enable_flow_log    = false
  block_ssh          = true
  block_rdp          = true
  single_nat_gateway = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO INTERNAL SERVICE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "internal" {
  name        = "internal"
  description = "Allow inbound traffic to internal service"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Access to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access to internal service"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "internal" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.internal_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "internal_flow_log" {
  name              = "internal_flow_log"
  retention_in_days = 14
}
