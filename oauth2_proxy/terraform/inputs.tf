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
  description = "The buzzfeed_sso auth session key"
  type        = string
  sensitive   = true
}

variable "session_cookie_secret" {
  description = "The buzzfeed_sso seed string for secure cookies"
  type        = string
  sensitive   = true
}

variable "buzzfeed_sso_client_id" {
  description = "The buzzfeed_sso client id"
  type        = string
  sensitive   = true
}

variable "buzzfeed_sso_client_secret" {
  description = "The buzzfeed_sso client secret"
  type        = string
  sensitive   = true
}

variable "buzzfeed_sso_google_client_id" {
  description = "The buzzfeed_sso google sso client id"
  type        = string
  sensitive   = true
}

variable "buzzfeed_sso_google_client_secret" {
  description = "The buzzfeed_sso google sso client secret"
  type        = string
  sensitive   = true
}
