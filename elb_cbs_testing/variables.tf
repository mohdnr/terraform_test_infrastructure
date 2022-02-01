variable "account_id" {
  description = "(Required) The account ID to perform actions on."
  type        = string
}

variable "billing_tag_key" {
  description = "The default tagging key"
  type        = string
  default     = "CostCentre"
}

variable "billing_tag_value" {
  description = "The default tagging value"
  type        = string
  default     = "elb-test"
}

variable "vpc_name" {
  type    = string
  default = "elb-test"
}

variable "vpc_cidr_block" {
  description = "IP CIDR block of the VPC"
  type        = string
  default     = "172.16.0.0/16"
}
