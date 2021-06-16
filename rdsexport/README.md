# RDS Export to S3

> Module to export RDS snapshot to S3 via Lambda.


## Usage

```hcl
locals {
  environment_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  account_vars         = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  region_vars          = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region           = local.region_vars.locals.aws_region
  namespace            = local.environment_vars.locals.namespace
}

dependency "database" {
  config_path = "../db"
}

terraform {
  source = "../../../../..//modules/rdsexport"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  region                     = local.aws_region
  namespace                  = local.namespace
  function_name              = "rds_snapshot_to_s3"
  db_identifier              = dependency.database.outputs.db_identifier
  schedule_expression        = "cron(0 8 1 * ? *)"  # Run at 8:00 am (UTC) every 1st day of the month
}
```


## Reference

- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ExportSnapshot.html

