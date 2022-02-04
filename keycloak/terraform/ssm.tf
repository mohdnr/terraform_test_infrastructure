resource "random_password" "keycloak_db_password" {
  length  = 16
  special = false
}

resource "random_string" "keycloak_db_user" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "keycloak_admin_user" {
  name  = "keycloak_admin_user"
  type  = "String"
  value = var.keycloak_user
}

resource "aws_ssm_parameter" "keycloak_admin_password" {
  name  = "keycloak_admin_password"
  type  = "String"
  value = var.keycloak_password
}

resource "aws_ssm_parameter" "keycloak_db_password" {
  name  = "keycloak_db_password"
  type  = "String"
  value = random_password.keycloak_db_password.result
}

resource "aws_ssm_parameter" "keycloak_db_user" {
  name  = "keycloak_db_user"
  type  = "String"
  value = random_string.keycloak_db_user.id
}
