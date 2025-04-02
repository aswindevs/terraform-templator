locals {
  name = "{{ .locals.name }}-{{ .locals.environment }}"
  
  tags = {
    {{- range $key, $value := .tags }}
    {{ $key }} = "{{ $value }}"
    {{- end }}
  }

  vpc_tags = merge(
    local.tags,
    {
      Name = "${local.name}-vpc"
    }
  )

  subnet_tags = {
    {{- range .vpc.subnets }}
    "{{ .type }}_{{ .availability_zone }}" = merge(
      local.tags,
      {
        Name = "${local.name}-{{ .type }}-{{ .availability_zone }}"
        Type = "{{ .type }}"
      }
    )
    {{- end }}
  }

  ecs_tags = merge(
    local.tags,
    {
      Name = "${local.name}-ecs-cluster"
    }
  )

  ecr_tags = {
    {{- range .ecr.repositories }}
    "{{ .name }}" = merge(
      local.tags,
      {
        Name = "${local.name}-{{ .name }}-repo"
      }
    )
    {{- end }}
  }
} 