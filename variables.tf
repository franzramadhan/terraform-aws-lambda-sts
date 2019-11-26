variable "environment" {
  type        = "string"
  description = "The environment of the application. Valid value may varies from development, testing, staging, production, or management."
}

variable "description" {
  type        = "string"
  description = "Brief descriptive name of Lambda instance profile."
}

variable "product_domain" {
  type        = "string"
  description = "Abbreviation of the product domain this ASG and its instances belongs to."
}

variable "service_name" {
  type        = "string"
  description = "Name of the service."
}

variable "role_max_session_duration" {
  description = "The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  default     = 3600
}

variable "domain_name" {
  type        = "string"
  description = "Domain name for API gateway."
  default     = ""
}

variable "allowed_cidr" {
  type        = "list"
  description = "List of allowed CIDR."
  default     = []
}

variable "assumed_role_arn" {
  type        = "string"
  description = "ARN of assumed IAM Role."
}
