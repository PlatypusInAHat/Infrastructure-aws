###############################################################################
# Layer 04-data - Dev tfvars
###############################################################################

region       = "ap-southeast-1"
project_name = "lab-aws"
environment  = "dev"

# Remote state bucket (replace ACCOUNT_ID)
state_bucket = "lab-aws-terraform-state-361183471902"

# RDS - No HA for dev
rds_engine_version          = "15.4"
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 50
database_name               = "appdb"
database_username           = "dbadmin"
database_port               = 5432
rds_multi_az                = false
rds_backup_retention_period = 1
rds_backup_window           = "03:00-04:00"
rds_maintenance_window      = "Mon:04:00-Mon:05:00"
rds_storage_type            = "gp3"

rds_parameters = [
  {
    name  = "log_connections"
    value = "1"
  },
  {
    name  = "log_disconnections"
    value = "1"
  }
]
rds_deletion_protection     = false
rds_skip_final_snapshot     = true
rds_performance_insights    = false
