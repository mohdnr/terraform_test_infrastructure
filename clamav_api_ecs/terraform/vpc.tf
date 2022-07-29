module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.1//vpc"
  name   = var.product_name

  high_availability = true
  enable_flow_log   = false
  enable_eip        = true
  block_ssh         = true
  block_rdp         = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

resource "aws_network_acl_rule" "api_ingress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 113
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 8000
  to_port        = 8000
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO CLAMAV
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "clamav" {
  name        = "clamav"
  description = "Allow inbound traffic to clamav load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to api"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound http connections to the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound https connections to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "clamav" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.clamav_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "clamav_flow_log" {
  name              = "clamav_flow_log"
  retention_in_days = 14
}
