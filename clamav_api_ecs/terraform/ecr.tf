#
# ECR
#
resource "aws_ecr_repository" "clamav" {
  name                 = "ecs/clamav"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
