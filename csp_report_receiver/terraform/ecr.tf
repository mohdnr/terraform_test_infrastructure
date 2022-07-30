resource "aws_ecr_repository" "csp_reports" {
  name                 = "csp-reports"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
