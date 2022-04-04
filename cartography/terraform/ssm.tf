resource "random_password" "neo4j_password" {
  length  = 16
  special = true
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
