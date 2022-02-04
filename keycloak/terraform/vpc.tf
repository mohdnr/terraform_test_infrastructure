locals {
  cidr_block = "10.0.0.0/16"
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.5//vpc"
  name   = "${var.product_name}_vpc"

  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = false

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

resource "aws_network_acl_rule" "https" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "https_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 110
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "ephemeral_ports_egress" {
  network_acl_id = module.vpc.main_nacl_id
  rule_number    = 111
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO KEYCLOAK
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "inbound_to_keycloak" {
  name        = "inbound_to_keycloak"
  description = "Allow inbound traffic to keycloak"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to keycloak"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to TLS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "keycloak" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.keycloak_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "keycloak_flow_log" {
  name              = "keycloak_flow_log"
  retention_in_days = 14
}
