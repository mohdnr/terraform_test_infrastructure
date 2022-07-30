resource "aws_ecs_cluster" "reporting" {
  name = "reporting"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
