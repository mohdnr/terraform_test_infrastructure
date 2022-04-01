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

variable "domain_name" {
  description = "The domain name of the sso proxy"
  type        = string
}

variable "session_key" {
  description = "The pomerium auth session key"
  type        = string
  sensitive   = true
}

variable "session_cookie_secret" {
  description = "The pomerium seed string for secure cookies"
  type        = string
  sensitive   = true
}

variable "pomerium_client_id" {
  description = "The pomerium client id"
  type        = string
  sensitive   = true
}

variable "pomerium_client_secret" {
  description = "The pomerium client secret"
  type        = string
  sensitive   = true
}

variable "pomerium_azure_client_id" {
  description = "The pomerium azure sso client id"
  type        = string
  sensitive   = true
}

variable "pomerium_azure_client_secret" {
  description = "The pomerium azure sso client secret"
  type        = string
  sensitive   = true
}

variable "pomerium_azure_provider_url" {
  description = "The pomerium azure sso provider url"
  type        = string
  sensitive   = true
}
