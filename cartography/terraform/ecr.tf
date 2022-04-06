#
# ECR
#
resource "aws_ecr_repository" "cartography" {
  name                 = "ecs/cartography"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "neo4j_ingestor" {
  name                 = "ecs/neo4j_ingestor"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
