data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Assume role policy for the central cbs account to manage config rules via Terraform
resource "aws_iam_role" "asset_inventory_security_audit_role" {
  name               = "AssetInventorySecurityAuditRole"
  assume_role_policy = data.aws_iam_policy_document.asset_inventory_execution_role.json
}

data "aws_iam_policy_document" "asset_inventory_execution_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.security_account_id}:role/AssetInventoryCartographyRole"]
    }
  }
}

data "aws_iam_policy" "security_audit" {
  name = "SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "security_audit" {
  role       = aws_iam_role.asset_inventory_security_audit_role.name
  policy_arn = data.aws_iam_policy.security_audit.arn
}
