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
  description = "AWS proxy integration URI."
  type        = string
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
  description = "Payload format version for the AWS proxy integration."
  type        = string
  default     = "2.0"
}

variable "tags" {
  description = "Tags applied to supported API Gateway resources."
  type        = map(string)
  default     = {}
}
