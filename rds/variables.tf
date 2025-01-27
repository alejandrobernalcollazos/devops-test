variable "allocated_storage" {
    description = "The amount of storage to allocate"
    type        = number
    default     = 20
}

variable "storage_type" {
    description = "The type of storage to use"
    type        = string
    default     = "gp2"
}

variable "engine" {
    description = "The database engine to use"
    type        = string
    default     = "mariadb"
}

variable "engine_version" {
    description = "The version of the database engine to use"
    type        = string
    default     = "11.4.4"
}

variable "instance_class" {
    description = "The instance class to use"
    type        = string
    default     = "db.t3.micro"
}

variable "db_name" {
    description = "The name of the database"
    type        = string
    default     = null
}

variable "username" {
    description = "The master username"
    type        = string
    default     = null
}

variable "password" {
    description = "The master password"
    type        = string
    default     = null
}

variable "parameter_group_name" {
    description = "The name of the parameter group"
    type        = string
    default     = null
}

variable "publicly_accessible" {
    description = "Whether the RDS instance is publicly accessible"
    type        = bool
    default     = false
}

variable "vpc_security_group_ids" {
    description = "The security group IDs"
    type        = list(string)
    default     = []
}

variable "db_subnet_group_name" {
    description = "The name of the subnet group"
    type        = string
    default     = ""
}

variable "skip_final_snapshot" {
    description = "Whether to skip the final snapshot"
    type        = bool
    default     = true
}

variable "replicate_source_db" {
    description = "The identifier of the replication source"
    type        = string
    default     = null
}

variable "backup_retention_period" {
    description = "The number of days to retain backups for"
    type        = number
    default     = null
}