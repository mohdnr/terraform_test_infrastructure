resource "aws_rds_cluster" "csp_reports" {
  cluster_identifier     = "csp-reports"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "13.6"
  database_name          = "csp_reports"
  master_username        = "csp_reports"
  master_password        = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.csp_reports.name
  vpc_security_group_ids = [aws_security_group.csp_reports.id]

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "csp_reports" {
  cluster_identifier = aws_rds_cluster.csp_reports.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.csp_reports.engine
  engine_version     = aws_rds_cluster.csp_reports.engine_version
}

resource "aws_db_subnet_group" "csp_reports" {
  name       = "csp-reports-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids

  tags = {
    Name = "csp-reports-subnet-group"
  }
}
