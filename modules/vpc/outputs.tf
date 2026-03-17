output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for s in aws_subnet.private : s.id]
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = [for s in aws_subnet.database : s.id]
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "nat_gateway_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = [for e in aws_eip.nat : e.public_ip]
}

output "availability_zones" {
  description = "Availability zones used"
  value       = local.azs
}
