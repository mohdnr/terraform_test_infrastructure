locals {
  cidr_block = "10.0.0.0/16"
}

module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.1//vpc"
  name   = var.product_name

  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_key   = "CostCentre"
  billing_tag_value = var.billing_code
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO ALLOW ACCESS TO DEPENDENCY TRACK
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "dependency_track" {
  name        = "dependency_track"
  description = "Allow inbound traffic to dependency_track load balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Access to load balancer"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Access to dependency_track"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Access to dependency_track"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Access to dependency_track"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  ingress {
    description = "Access to dependency_track"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }

  egress {
    description = "Access to RDS Postgresql"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }

  egress {
    description = "Access to efs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }

  ingress {
    description = "Access to efs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }
}

resource "aws_flow_log" "dependency_track" {
  iam_role_arn    = aws_iam_role.task_execution_role.arn
  log_destination = aws_cloudwatch_log_group.dependency_track_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_cloudwatch_log_group" "dependency_track_flow_log" {
  name              = "dependency_track_flow_log"
  retention_in_days = 14
}
