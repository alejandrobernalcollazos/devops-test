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

variable "certificate_arn_primary" {
  description = "The ARN of the certificate in the primary region"
  type        = string
  default     = "arn:aws:acm:us-west-2:438465167196:certificate/76cfe100-cce8-4223-8939-3ac856fffa86"
}

variable "certificate_arn_secondary" {
  description = "The ARN of the certificate in the secondary region"
  type        = string
  default     = "arn:aws:acm:us-east-1:438465167196:certificate/041c589f-fcd8-4305-b7b7-dec68275d1da"
}