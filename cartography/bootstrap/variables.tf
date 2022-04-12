variable "security_account_id" {
  description = "(Required) The account ID to centrally manage all accounts."
  type        = string
  default     = "794722365809"
}

variable "region" {
  description = "The current AWS region"
  type        = string
  default     = "ca-central-1"
}

