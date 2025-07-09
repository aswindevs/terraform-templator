
module "rds_prime" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "6.0.0"
  identifier                = "${local.project_prefix}-prime"
  engine                    = "postgres"
  engine_version            = "14"
  instance_class            = "db.t3.micro"
  family                    = "postgres14"
  username                  = "postgres"
  password                  = "xxxxxxxx"
  allocated_storage         = 20
  subnet_ids                = module.vpc_prime.private_subnets
  db_subnet_group_name      = "${local.project_prefix}-prime"
  create_db_subnet_group    = true
  create_db_option_group    = false
  create_db_parameter_group = true
  skip_final_snapshot       = true
  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-prime"
    }
  )
}
