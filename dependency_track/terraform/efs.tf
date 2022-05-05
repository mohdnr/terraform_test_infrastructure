resource "aws_efs_file_system" "dependency_track" {
  encrypted = true

  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}

resource "aws_efs_mount_target" "dependency_track" {
  count           = length(module.vpc.private_subnet_ids)
  file_system_id  = aws_efs_file_system.dependency_track.id
  subnet_id       = element(module.vpc.private_subnet_ids, count.index)
  security_groups = [aws_security_group.dependency_track.id]
}

resource "aws_efs_access_point" "dependency_track" {
  file_system_id = aws_efs_file_system.dependency_track.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 775
    }
  }
  tags = {
    (var.billing_tag_key) = var.billing_tag_value
    Terraform             = true
    Product               = var.product_name
  }
}
