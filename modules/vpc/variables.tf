variable "aws_region" {
  description = "AWS region for subnet availability zones"
  type        = string
}

variable "name_prefix" {
  description = "Organization or account naming prefix"
  type        = string
}

variable "team_prefix" {
  description = "Team or deployment naming prefix"
  type        = string
}

variable "vpc_name" {
  description = "Resource-specific VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability Zones that host the subnet tiers"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two Availability Zones are required."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
}

variable "storage_subnet_cidrs" {
  description = "CIDR blocks for private storage subnets"
  type        = list(string)
}

variable "additional_subnet_tiers" {
  description = "Additional subnet tiers keyed by tier name"
  type = map(object({
    cidr_blocks             = list(string)
    map_public_ip_on_launch = optional(bool, false)
  }))
  default = {}

  validation {
    condition = length(setintersection(
      toset(keys(var.additional_subnet_tiers)),
      toset(["public", "app", "database", "storage"]),
    )) == 0
    error_message = "Additional subnet tier names cannot replace built-in tiers."
  }
}
