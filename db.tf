# Create an RDS instance
resource "aws_db_instance" "mariadb" {
  allocated_storage    = 20                        # Storage size in GB
  storage_type         = "gp2"                     # General Purpose SSD
  engine               = "mariadb"                 # MariaDB engine
  engine_version       = "11.4.4"                  # Specify the MariaDB version
  instance_class       = "db.t3.micro"             # Instance type (modify as needed)
  name                 = "sample"                  # Database name
  username             = "tutorial_user"           # Master username
  password             = "masterpassword"          # Master password (shouldn't be hardcoded in production)
  parameter_group_name = "default.mariadb11.4"     # Parameter group for MariaDB
  publicly_accessible  = false                     # Set to true for public access (not recommended for production)
  vpc_security_group_ids = [                       # Security group IDs for access control
    aws_security_group.rds_sg.id
  ]
  skip_final_snapshot  = true                     # Set to false for production (ensures snapshot upon deletion)
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

output "db_endpoint" {
  value = aws_db_instance.mariadb.endpoint
}