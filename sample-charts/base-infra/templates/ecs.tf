{{- if .ecs.enable -}}
{{- range $key, $value := .ecs }}
{{- if ne $key "enable" }}
module "ecs_{{ $key }}" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = "${local.project_prefix}-{{ $key }}"

  # Cluster configuration
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.project_prefix}-{{ $key }}"
      }
    }
  }

  # CloudWatch Log Groups
  cloudwatch_log_group_name              = "/aws/ecs/${local.project_prefix}-{{ $key }}"
  cloudwatch_log_group_retention_in_days = {{ .log_retention_days | default 14 }}

  # Cluster settings
  cluster_settings = {
    "name"  = "containerInsights"
    "value" = "{{ .container_insights | ternary "enabled" "disabled" }}"
  }

  {{- if .capacity_providers }}
  # Capacity providers
  default_capacity_provider_use_fargate = {{ has "FARGATE" .capacity_providers }}
  fargate_capacity_providers = {
    {{- if has "FARGATE" .capacity_providers }}
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = {{ (index .default_capacity_provider_strategy 0).weight | default 1 }}
        base   = {{ (index .default_capacity_provider_strategy 0).base | default 0 }}
      }
    }
    {{- end }}
    {{- if has "FARGATE_SPOT" .capacity_providers }}
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = {{ (index .default_capacity_provider_strategy 1).weight | default 1 }}
        base   = {{ (index .default_capacity_provider_strategy 1).base | default 0 }}
      }
    }
    {{- end }}
  }
  {{- end }}

  {{- if .autoscaling }}
  # Autoscaling
  autoscaling_capacity_providers = {
    {{- range .capacity_providers }}
    {{ . }} = {
      auto_scaling_group_arn         = ""
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
    {{- end }}
  }
  {{- end }}

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}"
    }
  )
}

{{- if .service_discovery }}
# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "{{ $key }}" {
  name        = "{{ .service_discovery.namespace }}"
  description = "Service discovery namespace for {{ $key }}"
  vpc         = module.vpc_prime.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-discovery"
    }
  )
}
{{- end }}

{{- end }}
{{- end }}
{{- end }} 