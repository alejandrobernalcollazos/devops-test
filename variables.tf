# Create primary region variable
variable "primary_region" {
  description = "The primary region to deploy resources"
  type        = string
  default     = "us-west-2"
}

# Create secondary region variable
variable "secondary_region" {
  description = "The secondary region to deploy resources"
  type        = string
  default     = "us-east-1"
}