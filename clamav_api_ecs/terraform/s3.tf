locals {
  name_prefix = "${var.product_name}-test-speed"
  clamav-defs = "${local.name_prefix}-clamav-defs"
}

module "log_bucket" {
  source            = "github.com/cds-snc/terraform-modules?ref=v0.0.47//S3_log_bucket"
  bucket_name       = replace("${var.product_name}-test-speed-logs", "_", "-")
  billing_tag_value = var.billing_code
}

module "clamav-defs" {
  source            = "github.com/cds-snc/terraform-modules?ref=v0.0.47//S3"
  bucket_name       = replace(local.clamav-defs, "_", "-")
  billing_tag_value = var.billing_code
  logging = {
    "target_bucket" = module.log_bucket.s3_bucket_id
    "target_prefix" = local.clamav-defs
  }
}
