resource "aws_ecs_cluster" "software_dependency_tracking" {
  name = "software_dependency_tracking"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
