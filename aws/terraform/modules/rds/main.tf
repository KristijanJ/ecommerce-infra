# Allow the EKS nodes (and the pods running on them) to reach Postgres
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-${var.environment}"
  description = "Postgres access from the EKS nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-rds-${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres_from_nodes" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = var.node_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres from EKS nodes"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 7.2"

  identifier = "${var.project_name}-postgres-${var.environment}"

  engine         = "postgres"
  engine_version = "18"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.username
  port     = 5432

  # RDS generates the master password and stores it in Secrets Manager
  manage_master_user_password = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Use the subnet group created by the networking module
  create_db_subnet_group = false
  db_subnet_group_name   = var.database_subnet_group_name

  # DB parameter group (Postgres has no option group)
  family                 = "postgres18"
  major_engine_version   = "18"
  create_db_option_group = false

  parameters = [
    {
      # The backend does not use SSL yet. Remove this once TypeORM connects with ssl.
      name  = "rds.force_ssl"
      value = "0"
    }
  ]

  # Learning setup: created and destroyed every session
  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
}
