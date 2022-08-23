resource "aws_ecr_repository" "csp_reports" {
  name                 = "csp-reports"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "purge_csp_reports" {
  name                 = "purge-csp-reports"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
