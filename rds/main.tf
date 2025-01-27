
# Create an RDS instance
resource "aws_db_instance" "mariadb" {
  allocated_storage       = var.allocated_storage        # Storage size in GB
  storage_type            = var.storage_type             # General Purpose SSD
  engine                  = var.engine                   # MariaDB engine
  engine_version          = var.engine_version           # Specify the MariaDB version
  instance_class          = var.instance_class           # Instance type (modify as needed)
  db_name                 = var.db_name                  # Database name
  username                = var.username                 # Master username
  password                = var.password                 # Master password (shouldn't be hardcoded in production)
  parameter_group_name    = var.parameter_group_name     # Parameter group for MariaDB
  publicly_accessible     = var.publicly_accessible      # Set to false for production
  vpc_security_group_ids  = var.vpc_security_group_ids   # Security group for the RDS instance
  skip_final_snapshot     = var.skip_final_snapshot      # Set to false for production (ensures snapshot upon deletion)
  db_subnet_group_name    = var.db_subnet_group_name     # Subnet group for the RDS instance
  replicate_source_db     = var.replicate_source_db      # Source DB for replication if needed
  backup_retention_period = var.backup_retention_period  # Retain backups for 7 days
}

# Create a security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for MariaDB RDS instance"

  ingress {
    from_port   = 3306                            # MariaDB default port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]                   # Open to the world (restrict for production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
