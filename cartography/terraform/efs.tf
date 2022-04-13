resource "aws_efs_file_system" "neo4j" {
  tags = {
    billing_tag_key   = "CostCentre"
    billing_tag_value = var.billing_code
  }
}

resource "aws_efs_mount_target" "neo4j" {
  count           = length(module.vpc.private_subnet_ids)
  file_system_id  = aws_efs_file_system.neo4j.id
  subnet_id       = element(module.vpc.private_subnet_ids, count.index)
  security_groups = [aws_security_group.cartography.id]
}
