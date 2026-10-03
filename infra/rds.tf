# Alphanumeric only, so the values can be embedded in shell/SQL/JDBC without escaping.
resource "random_password" "db_admin" {
  length  = 24
  special = false
}

resource "random_password" "db_app" {
  length  = 24
  special = false
}

locals {
  db_name       = "anitracker"
  db_admin_user = "anitracker_admin"
  db_app_user   = "app_user"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.project_name}-db-subnets" }
}

# Log RDS read/write the app makes
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-db-params"
  family = "postgres${var.db_engine_version}"

  parameter {
    name         = "log_statement"
    value        = "all"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_connections"
    value        = "1"
    apply_method = "immediate"
  }

  tags = { Name = "${var.project_name}-db-params" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = local.db_name
  username = local.db_admin_user
  password = random_password.db_admin.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  parameter_group_name   = aws_db_parameter_group.main.name

  # Publishes the PostgreSQL log to CloudWatch: /aws/rds/instance/<project>-db/postgresql
  enabled_cloudwatch_logs_exports = ["postgresql"]

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = { Name = "${var.project_name}-db" }
}
