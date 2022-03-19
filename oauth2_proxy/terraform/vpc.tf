module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v1.0.5//vpc"
  name   = var.product_name

  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

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
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO BUZZFEED SSO
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "buzzfeed_sso" {
  name        = "buzzfeed_sso"
  description = "Allow inbound traffic to buzzfeed_sso load balancer"
  vpc_id      = module.vpc.vpc_id


  ingress {
    description = "Access to load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Access from proxy"
    from_port   = 4180
    to_port     = 4180
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow API outbound connections to the proxy"
    from_port   = 4180
    to_port     = 4180
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "buzzfeed_sso" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.buzzfeed_sso_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "buzzfeed_sso_flow_log" {
  name              = "buzzfeed_sso_flow_log"
  retention_in_days = 14
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS FROM SSO TO INTERNAL APPS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "internal_apps" {
  name        = "internal_apps"
  description = "Allow inbound traffic to internal_apps"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Access from proxy"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.buzzfeed_sso.id]
  }

  ingress {
    description     = "Access from proxy"
    from_port       = 4180
    to_port         = 4180
    protocol        = "tcp"
    security_groups = [aws_security_group.buzzfeed_sso.id]
  }

  egress {
    description     = "Access from proxy"
    from_port       = 4180
    to_port         = 4180
    protocol        = "tcp"
    security_groups = [aws_security_group.buzzfeed_sso.id]
  }

  egress {
    description = "Allow API outbound connections to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_flow_log" "internal_apps" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.internal_apps_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "internal_apps_flow_log" {
  name              = "internal_apps_flow_log"
  retention_in_days = 14
}
