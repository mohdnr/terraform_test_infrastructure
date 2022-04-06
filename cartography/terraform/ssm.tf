resource "random_password" "neo4j_password" {
  length  = 16
  special = true
}

resource "random_password" "elasticsearch_password" {
  length  = 16
  special = true
}

resource "random_string" "elasticsearch_user" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "neo4j_password" {
  name  = "neo4j_password"
  type  = "String"
  value = random_password.neo4j_password.result
}

resource "aws_ssm_parameter" "neo4j_auth" {
  name  = "neo4j_auth"
  type  = "String"
  value = "neo4j/${random_password.neo4j_password.result}"
}

resource "aws_ssm_parameter" "elasticsearch_user" {
  name  = "elasticsearch_user"
  type  = "String"
  value = random_string.elasticsearch_user.id
}

resource "aws_ssm_parameter" "elasticsearch_password" {
  name  = "elasticsearch_password"
  type  = "String"
  value = random_password.elasticsearch_password.result
}
