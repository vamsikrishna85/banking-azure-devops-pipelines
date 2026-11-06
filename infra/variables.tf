variable "service" {
  type    = string
  default = "payments"
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "sit", "uat", "prod"], var.environment)
    error_message = "environment must be dev, sit, uat or prod."
  }
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
