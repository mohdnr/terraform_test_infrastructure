module "vpc" {
  source = "github.com/cds-snc/terraform-modules?ref=v2.0.1//vpc"
  name   = "security-tools"

  high_availability = true
  enable_flow_log   = false
  block_ssh         = true
  block_rdp         = true
  enable_eip        = true

  allow_https_request_out          = true
  allow_https_request_out_response = true
  allow_https_request_in           = true
  allow_https_request_in_response  = true

  billing_tag_value = "security-tools"
}
