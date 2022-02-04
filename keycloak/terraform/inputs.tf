variable "product_name" {
  description = "(Required) The name of the product you are deploying."
  type        = string
}

variable "billing_code" {
  description = "The billing code to tag our resources with"
  type        = string
}

variable "region" {
  description = "The current AWS region"
  type        = string
}

variable "keycloak_user" {
  description = "The keycloak admin username"
  type        = string
  sensitive   = true
}

variable "keycloak_password" {
  description = "The keycloak admin password"
  type        = string
  sensitive   = true
}
