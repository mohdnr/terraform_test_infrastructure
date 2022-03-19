resource "aws_ssm_parameter" "buzzfeed_sso_google_client_id" {
  name  = "buzzfeed_sso_google_client_id"
  type  = "String"
  value = var.buzzfeed_sso_google_client_id
}

resource "aws_ssm_parameter" "buzzfeed_sso_google_client_secret" {
  name  = "buzzfeed_sso_google_client_secret"
  type  = "String"
  value = var.buzzfeed_sso_google_client_secret
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

resource "aws_ssm_parameter" "buzzfeed_sso_client_id" {
  name  = "buzzfeed_sso_client_id"
  type  = "String"
  value = var.buzzfeed_sso_client_id
}

resource "aws_ssm_parameter" "buzzfeed_sso_client_secret" {
  name  = "buzzfeed_sso_client_secret"
  type  = "String"
  value = var.buzzfeed_sso_client_secret
}
