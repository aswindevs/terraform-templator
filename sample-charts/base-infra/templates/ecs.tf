{{- if .ecs.enable -}}
{{- range $key, $value := .ecs }}
{{- if ne $key "enable" }}
# ECS Cluster
resource "aws_ecs_cluster" "{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}"

  setting {
    name  = "containerInsights"
    value = "{{ .container_insights | ternary "enabled" "disabled" }}"
  }

  {{- if .capacity_providers }}
  capacity_providers = {{ .capacity_providers | toJson }}
  {{- end }}

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}"
    }
  )
}

{{- if .capacity_providers }}
# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "{{ $key }}" {
  cluster_name = aws_ecs_cluster.{{ $key }}.name

  capacity_providers = {{ .capacity_providers | toJson }}

  {{- if .default_capacity_provider_strategy }}
  {{- range .default_capacity_provider_strategy }}
  default_capacity_provider_strategy {
    capacity_provider = "{{ .capacity_provider }}"
    weight            = {{ .weight }}
    {{- if .base }}
    base              = {{ .base }}
    {{- end }}
  }
  {{- end }}
  {{- end }}
}
{{- end }}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "{{ $key }}" {
  name              = "/ecs/${local.project_prefix}-{{ $key }}"
  retention_in_days = {{ .log_retention_days | default 14 }}

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-logs"
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

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-task-execution"
    }
  )
}

# Attach ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_{{ $key }}" {
  role       = aws_iam_role.ecs_task_execution_{{ $key }}.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-task"
    }
  )
}

{{- if .autoscaling }}
# Auto Scaling Role
resource "aws_iam_role" "ecs_autoscaling_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-autoscaling"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-autoscaling"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_{{ $key }}" {
  role       = aws_iam_role.ecs_autoscaling_{{ $key }}.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
}
{{- end }}

{{- end }}
{{- end }}
{{- end }} 