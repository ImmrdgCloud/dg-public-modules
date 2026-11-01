variable "name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "description" {
  description = "Description of the HTTP API."
  type        = string
  default     = null
}

variable "integration_uri" {
  description = "Backend integration URI."
  type        = string
}

variable "integration_type" {
  description = "API Gateway integration type."
  type        = string
  default     = "AWS_PROXY"
}

variable "integration_method" {
  description = "HTTP method sent to the backend."
  type        = string
  default     = "POST"
}

variable "route_key" {
  description = "HTTP API route key."
  type        = string
  default     = "ANY /{proxy+}"
}

variable "stage_name" {
  description = "HTTP API stage name."
  type        = string
  default     = "$default"
}

variable "payload_format_version" {
  description = "Payload format version for proxy integrations."
  type        = string
  default     = "2.0"
}

variable "tags" {
  description = "Tags applied to supported API Gateway resources."
  type        = map(string)
  default     = {}
}
