###############################################################################
# Layer 01-network - Dev tfvars
###############################################################################

region       = "ap-southeast-1"
project_name = "lab-aws"
environment  = "dev"

# VPC - Cost-optimized for dev
vpc_cidr           = "10.0.0.0/16"
az_count           = 2
single_nat_gateway = true
