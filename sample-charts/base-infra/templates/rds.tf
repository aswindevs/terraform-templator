{{- if .rds -}}
{{- range $key, $value := .rds }}
module "rds_{{ $key }}" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  identifier = "${local.name}-db-{{ $key }}"

  engine            = "{{ $value.engine }}"
  engine_version    = "{{ $value.engine_version }}"
  instance_class    = "{{ $value.instance_class }}"
  allocated_storage = {{ $value.allocated_storage }}

  db_name  = "{{ $value.db_name }}"
  username = "{{ $value.username }}"
  password = "{{ $value.password }}"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  db_subnet_group_name   = "${local.name}-db-subnet-group-{{ $key }}"
  create_db_subnet_group = true

  create_db_option_group    = false
  create_db_parameter_group = false

  skip_final_snapshot = true

  tags = merge(
    local.tags,
    {
      Name = "${local.name}-db-{{ $key }}"
    }
  )
}
{{- end }}
{{- end }}
