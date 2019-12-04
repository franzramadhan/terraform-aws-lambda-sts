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
  type        = "string"
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

variable "stage_name" {
  type        = "string"
  description = "API Gateway Deployment stage name."
  default     = "v1"
}

# API Gateway Usage Plan

variable "quota_limit" {
  type        = "string"
  description = "The maximum number of requests that can be made in a given time period."
  default     = 96
}

variable "quota_offset" {
  type        = "string"
  description = "The number of requests subtracted from the given limit in the initial time period."
  default     = 0
}

variable "quota_period" {
  type        = "string"
  description = "The time period in which the limit applies. Valid values are DAY, WEEK or MONTH."
  default     = "DAY"
}

variable "throttle_burst_limit" {
  type        = "string"
  description = "The API request burst limit, the maximum rate limit over a time ranging from one to a few seconds, depending upon whether the underlying token bucket is at its full capacity."
  default     = 5
}

variable "throttle_rate_limit" {
  type        = "string"
  description = " The API request steady-state rate limit."
  default     = 10
}
