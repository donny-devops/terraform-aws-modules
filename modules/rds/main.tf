terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5"
}

locals {
  common_tags = merge(
    { Module = "rds", ManagedBy = "terraform" },
    var.tags,
  )
}

# ── Subnet Group ───────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnet-group"
  description = "Subnet group for ${var.name} RDS instance"
  subnet_ids  = var.subnet_ids
  tags        = local.common_tags
}

# ── Security Group ─────────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for ${var.name} RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-rds-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = each.value
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from allowed security group"
}

# ── Parameter Group ────────────────────────────────────────────────────────────

resource "aws_db_parameter_group" "this" {
  name        = "${var.name}-postgres-params"
  family      = "postgres16"
  description = "Custom parameter group for ${var.name}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = local.common_tags
}

# ── RDS Instance ───────────────────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier = var.name

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  multi_az               = var.multi_az
  publicly_accessible    = false
  deletion_protection    = var.deletion_protection
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.name}-final-snapshot"
  copy_tags_to_snapshot  = true

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  auto_minor_version_upgrade = true
  apply_immediately          = false

  tags = local.common_tags
}
