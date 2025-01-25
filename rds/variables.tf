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

variable "name" {
    description = "The name of the database"
    type        = string
    default     = "sample"
}

variable "username" {
    description = "The master username"
    type        = string
    default     = "tutorial_user"
}

variable "password" {
    description = "The master password"
    type        = string
    default     = "masterpassword"
}

variable "parameter_group_name" {
    description = "The name of the parameter group"
    type        = string
    default     = "default.mariadb11.4"
}
