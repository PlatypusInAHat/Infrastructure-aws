###############################################################################
# VPC Module
# Creates VPC with Public, Private, and Database subnets across multiple AZs
###############################################################################

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Mapping of index to AZ name for stable keys
  az_map = { for i, az in local.azs : i => az }

  public_subnets   = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 4, i) }
  private_subnets  = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 4, i + 3) }
  database_subnets = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, 4, i + 6) }
}

# ---------- VPC ----------

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# ---------- Internet Gateway ----------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# ---------- Public Subnets ----------

resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[each.value]
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-public-${each.value}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# ---------- Private Subnets ----------

resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets[each.value]
  availability_zone = each.value

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-private-${each.value}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# ---------- Database Subnets ----------

resource "aws_subnet" "database" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.database_subnets[each.value]
  availability_zone = each.value

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-database-${each.value}"
  })
}

# ---------- NAT Gateway ----------

resource "aws_eip" "nat" {
  for_each = var.single_nat_gateway ? toset([local.azs[0]]) : toset(local.azs)
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${each.value}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  for_each = var.single_nat_gateway ? toset([local.azs[0]]) : toset(local.azs)

  allocation_id = aws_eip.nat[each.value].id
  subnet_id     = aws_subnet.public[each.value].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-${each.value}"
  })

  depends_on = [aws_internet_gateway.this]
}

# ---------- Route Tables ----------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = toset(local.azs)

  subnet_id      = aws_subnet.public[each.value].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = var.single_nat_gateway ? toset([local.azs[0]]) : toset(local.azs)
  vpc_id   = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${each.value}"
  })
}

resource "aws_route" "private_nat" {
  for_each = var.single_nat_gateway ? toset([local.azs[0]]) : toset(local.azs)

  route_table_id         = aws_route_table.private[each.value].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.value].id
}

resource "aws_route_table_association" "private" {
  for_each = toset(local.azs)

  subnet_id      = aws_subnet.private[each.value].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? local.azs[0] : each.value].id
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-database-rt"
  })
}

resource "aws_route_table_association" "database" {
  for_each = toset(local.azs)

  subnet_id      = aws_subnet.database[each.value].id
  route_table_id = aws_route_table.database.id
}

# ---------- DB Subnet Group ----------

resource "aws_db_subnet_group" "this" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "Database subnet group for ${var.project_name} ${var.environment}"
  subnet_ids  = [for s in aws_subnet.database : s.id]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# ---------- Moved blocks for state migration ----------

moved {
  from = aws_subnet.public[0]
  to   = aws_subnet.public["ap-southeast-1a"]
}

moved {
  from = aws_subnet.public[1]
  to   = aws_subnet.public["ap-southeast-1b"]
}

moved {
  from = aws_subnet.private[0]
  to   = aws_subnet.private["ap-southeast-1a"]
}

moved {
  from = aws_subnet.private[1]
  to   = aws_subnet.private["ap-southeast-1b"]
}

moved {
  from = aws_subnet.database[0]
  to   = aws_subnet.database["ap-southeast-1a"]
}

moved {
  from = aws_subnet.database[1]
  to   = aws_subnet.database["ap-southeast-1b"]
}

moved {
  from = aws_eip.nat[0]
  to   = aws_eip.nat["ap-southeast-1a"]
}

moved {
  from = aws_nat_gateway.this[0]
  to   = aws_nat_gateway.this["ap-southeast-1a"]
}

moved {
  from = aws_route_table.private[0]
  to   = aws_route_table.private["ap-southeast-1a"]
}

moved {
  from = aws_route_table_association.public[0]
  to   = aws_route_table_association.public["ap-southeast-1a"]
}

moved {
  from = aws_route_table_association.public[1]
  to   = aws_route_table_association.public["ap-southeast-1b"]
}

moved {
  from = aws_route_table_association.private[0]
  to   = aws_route_table_association.private["ap-southeast-1a"]
}

moved {
  from = aws_route_table_association.private[1]
  to   = aws_route_table_association.private["ap-southeast-1b"]
}

moved {
  from = aws_route_table_association.database[0]
  to   = aws_route_table_association.database["ap-southeast-1a"]
}

moved {
  from = aws_route_table_association.database[1]
  to   = aws_route_table_association.database["ap-southeast-1b"]
}
