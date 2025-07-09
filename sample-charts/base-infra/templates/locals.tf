locals {
  name           = "{{ .locals.name }}"
  environment    = "{{ .locals.environment }}"
  region         = "{{ .locals.region }}"
  project_prefix = "${local.name}-${local.environment}-${local.region_code[local.region]}"
  tags = {
    {{- range $key, $value := .locals.tags }}
    {{ printf "%-12s" $key }} = "{{ $value }}"
    {{- end }}
  }

  vpc_tags = merge(
    local.tags,
    {
      Name = "${local.name}-vpc"
    }
  )

  subnet_tags = {
    {{- if .vpc.enable -}}
    {{- range $vpcKey, $vpcValue := .vpc }}
    {{- if ne $vpcKey "enable" }}
    {{- range .subnets }}
    "{{ .type }}_{{ .availability_zone }}" = merge(
      local.tags,
      {
        Name = "${local.name}-{{ .type }}-{{ .availability_zone }}"
        Type = "{{ .type }}"
      }
    )
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
  }

  {{- if .eks.enable }}
  eks_tags = merge(
    local.tags,
    {
      Name = "${local.name}-eks-cluster"
    }
  )
  {{- end }}

  {{- if .ecs.enable }}
  ecs_tags = merge(
    local.tags,
    {
      Name = "${local.name}-ecs-cluster"
    }
  )
  {{- end }}

  {{- if .ecr.enable }}
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
  {{- end }}

  region_code = {
    us-east-2      = "oh" # Ohio
    us-east-1      = "nv" # US East (N. Virginia)
    us-west-1      = "ca" # N. California
    us-west-2      = "or" # US West (Oregon)
    ap-east-1      = "hk" # Hong Kong
    ap-south-1     = "mb" # Asia Pacific (Mumbai)
    ap-northeast-3 = "os" # Osaka-Local
    ap-northeast-2 = "se" # Asia Pacific (Seoul)
    ap-southeast-1 = "sg" # Singapore
    ap-southeast-2 = "sd" # Asia Pacific (Sydney)
    ap-northeast-1 = "tk" # Tokyo
    ca-central-1   = "cn" # Canada (Central)
    eu-central-1   = "ff" # Frankfurt
    eu-west-1      = "ie" # Europe (Ireland)
    eu-west-2      = "ld" # London
    eu-west-3      = "pr" # Europe (Paris)
    eu-north-1     = "st" # Stockholm
    me-south-1     = "bh" # Middle East (Bahrain)
    sa-east-1      = "sp" # São Paulo
  }
} 