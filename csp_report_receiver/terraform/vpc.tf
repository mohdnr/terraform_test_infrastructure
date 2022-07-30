module "vpc" {
  source             = "github.com/cds-snc/terraform-modules?ref=v3.0.5//vpc"
  name               = "csp-reports-ecs"
  billing_tag_value  = var.billing_code
  high_availability  = true
  block_ssh          = true
  block_rdp          = true
  single_nat_gateway = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true
}

resource "aws_security_group" "csp_reports" {
  # checkov:skip=CKV2_AWS_5: False-positive, SG is attached in lambda.tf

  name        = "csp_reports_sg"
  description = "SG for the CSP Reports lambda"

  vpc_id = module.vpc.vpc_id

  tags = {
    Name       = "csp_reports_sg"
    CostCentre = var.billing_code
    Terraform  = true
  }
}

resource "aws_security_group_rule" "port_443_egress" {
  description       = "Security group rule for egress to port 443"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csp_reports.id
}

resource "aws_security_group_rule" "port_8000_egress" {
  description              = "Security group rule for egress to port 8000 (csp report server)"
  type                     = "egress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.csp_reports.id
  source_security_group_id = aws_security_group.csp_reports.id
}

resource "aws_security_group_rule" "port_8000_ingress" {
  description              = "Security group rule for ingress to port 8000 (csp report server)"
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.csp_reports.id
  source_security_group_id = aws_security_group.csp_reports.id
}

resource "aws_security_group_rule" "port_5432_egress" {
  description              = "Security group rule for egress to port 5432 (postgres)"
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.csp_reports.id
  source_security_group_id = aws_security_group.csp_reports.id
}

resource "aws_security_group_rule" "port_5432_ingress" {
  description              = "Security group rule for ingress to port 5432 (postgres)"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.csp_reports.id
  source_security_group_id = aws_security_group.csp_reports.id
}

resource "aws_security_group_rule" "port_443_ingress" {
  description       = "Security group rule for ingress to port 443"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.csp_reports.id
}


