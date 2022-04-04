locals {
  asset_inventory_role = "AssetInventoryRole"
}

resource "aws_iam_role" "asset_inventory_role" {
  name               = local.asset_inventory_role
  assume_role_policy = data.aws_iam_policy_document.asset_inventory_role.json
}

data "aws_iam_policy_document" "asset_inventory_role" {
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
      identifiers = ["arn:aws:iam::028051698106:role/container_execution_role"]
    }
  }
}

data "aws_iam_policy" "read_only" {
  name = "ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "read_only" {
  role       = local.asset_inventory_role
  policy_arn = data.aws_iam_policy.read_only.arn
  depends_on = [aws_iam_role.asset_inventory_role]
}

