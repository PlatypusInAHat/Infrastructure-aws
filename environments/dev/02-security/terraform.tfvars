###############################################################################
# Layer 02-security - Dev tfvars
###############################################################################

region       = "ap-southeast-1"
project_name = "lab-aws"
environment  = "dev"

# Remote state bucket (replace ACCOUNT_ID)
state_bucket = "lab-aws-terraform-state-361183471902"

# Database port for RDS security group
db_port = 5432
