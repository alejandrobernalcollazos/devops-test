module "rds_primary" {
  source = "./rds"

  providers = {
    aws = aws.primary
  }

  allocated_storage = 20
  storage_type      = "gp2"
  engine            = "mariadb"
  engine_version    = "11.4.4"
  instance_class    = "db.t3.micro"
  name              = "sample"
  username          = "tutorial_user"
  password          = "masterpassword"
  parameter_group_name = "default.mariadb11.4"

}

/* module "rds_secondary" {
  source = "./rds"

  providers = {
    aws = aws.secondary
  }

  region            = var.secondary_region
  db_instance_class = "db.t3.medium"
  ...
} */

module "ec2_instance" {
  source = "./application"

  providers = {
    aws = aws.primary
  }

  ami              = "ami-093a4ad9a8cc370f4"
  instance_type    = "t2.micro"
  name             = "DevOpsTestInstance"
  mariadb_endpoint = module.rds_primary.db_endpoint
}