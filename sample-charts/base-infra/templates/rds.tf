{{- if .rds.enable -}}
{{- range $key, $value := .rds }}
{{- if ne $key "enable" }}
module "rds_{{ $key }}" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "6.0.0"
  identifier                = "${local.project_prefix}-{{ $key }}"
  engine                    = "{{ .engine }}"
  engine_version            = "{{ .engine_version }}"
  instance_class            = "{{ .instance_class }}"
  family                    = "{{ .engine }}{{ .engine_version }}"
  username                  = "{{ .username }}"
  password                  = "{{ .password }}"
  allocated_storage         = {{ .allocated_storage }}
  subnet_ids                = module.vpc_{{ $key }}.private_subnets
  db_subnet_group_name      = "${local.project_prefix}-{{ $key }}"
  create_db_subnet_group    = true
  create_db_option_group    = false
  create_db_parameter_group = true
  skip_final_snapshot       = true
  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}"
    }
  )
}
{{- end }}
{{- end }}
{{- end }}
