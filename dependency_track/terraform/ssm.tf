resource "random_password" "dependency_track_db_password" {
  length  = 32
  special = true
}

resource "random_string" "dependency_track_db_user" {
  length  = 10
  special = false
}

resource "aws_ssm_parameter" "dependency_track_db_password" {
  name  = "dependency_track_db_password"
  type  = "String"
  value = random_password.dependency_track_db_password.result
}

resource "aws_ssm_parameter" "dependency_track_db_user" {
  name  = "dependency_track_db_user"
  type  = "String"
  value = random_string.dependency_track_db_user.id
}
