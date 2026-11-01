locals {
  full_name = "${var.account_name}-${var.project}"

  subnet_tiers = merge({
    public = {
      cidr_blocks             = var.public_subnet_cidrs
      map_public_ip_on_launch = true
    },
    app = {
      cidr_blocks             = var.app_subnet_cidrs
      map_public_ip_on_launch = false
    },
    database = {
      cidr_blocks             = var.db_subnet_cidrs
      map_public_ip_on_launch = false
    },
    storage = {
      cidr_blocks             = var.storage_subnet_cidrs
      map_public_ip_on_launch = false
    },
  }, var.additional_subnet_tiers)

  subnet_definitions = merge([
    for tier, configuration in local.subnet_tiers : {
      for index, cidr_block in configuration.cidr_blocks :
      "${tier}-${index + 1}" => {
        availability_zone       = var.availability_zones[index % length(var.availability_zones)]
        cidr_block              = cidr_block
        map_public_ip_on_launch = configuration.map_public_ip_on_launch
        tier                    = tier
      }
    }
  ]...)

  common_tags = {
    ManagedBy = "terraform"
    Project   = var.project
  }
}

resource "aws_vpc" "shared_services" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-vpc"
  })
}

resource "aws_internet_gateway" "shared_services" {
  vpc_id = aws_vpc.shared_services.id

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-igw"
  })
}

resource "aws_subnet" "this" {
  for_each = local.subnet_definitions

  vpc_id                  = aws_vpc.shared_services.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-${each.key}-subnet"
    Tier = each.value.tier
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.shared_services.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shared_services.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = {
    for key, subnet in aws_subnet.this :
    key => subnet if local.subnet_definitions[key].tier == "public"
  }

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.shared_services.id

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  for_each = {
    for key, subnet in aws_subnet.this :
    key => subnet if local.subnet_definitions[key].tier != "public"
  }

  route_table_id = aws_route_table.private.id
  subnet_id      = each.value.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.shared_services.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(local.common_tags, {
    Name = "${local.full_name}-s3-endpoint"
  })
}
