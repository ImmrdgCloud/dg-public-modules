variable "name_prefix" {
  type = string
}

variable "team_prefix" {
  type = string
}

variable "parameter_name" {
  type = string
}

variable "value" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
