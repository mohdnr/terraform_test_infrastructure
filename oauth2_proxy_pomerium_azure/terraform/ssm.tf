resource "aws_ssm_parameter" "pomerium_azure_client_id" {
  name  = "pomerium_azure_client_id"
  type  = "String"
  value = var.pomerium_azure_client_id
}

resource "aws_ssm_parameter" "pomerium_azure_client_secret" {
  name  = "pomerium_azure_client_secret"
  type  = "String"
  value = var.pomerium_azure_client_secret
}

resource "aws_ssm_parameter" "pomerium_azure_provider_url" {
  name  = "pomerium_azure_provider_url"
  type  = "String"
  value = var.pomerium_azure_provider_url
}

resource "aws_ssm_parameter" "session_cookie_secret" {
  name  = "session_cookie_secret"
  type  = "String"
  value = var.session_cookie_secret
}

resource "aws_ssm_parameter" "session_key" {
  name  = "session_key"
  type  = "String"
  value = var.session_key
}

resource "aws_ssm_parameter" "pomerium_client_id" {
  name  = "pomerium_client_id"
  type  = "String"
  value = var.pomerium_client_id
}

resource "aws_ssm_parameter" "pomerium_client_secret" {
  name  = "pomerium_client_secret"
  type  = "String"
  value = var.pomerium_client_secret
}
