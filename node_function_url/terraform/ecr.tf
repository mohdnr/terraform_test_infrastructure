#
# ECR
#
resource "aws_ecr_repository" "lambda" {
  name                 = "lambda/docker"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}