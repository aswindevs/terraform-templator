{{- if .eks.enable -}}
{{- range $key, $value := .eks }}
{{- if ne $key "enable" }}
module "eks_{{ $key }}" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${local.project_prefix}-{{ $key }}"
  cluster_version = "{{ .cluster_version | default "1.28" }}"

  # VPC configuration
  vpc_id                          = module.vpc_prime.vpc_id
  subnet_ids                      = concat(module.vpc_prime.private_subnets, module.vpc_prime.public_subnets)
  cluster_endpoint_private_access = {{ .endpoint_private_access | default "true" }}
  cluster_endpoint_public_access  = {{ .endpoint_public_access | default "true" }}
  {{- if .endpoint_public_access_cidrs }}
  cluster_endpoint_public_access_cidrs = {{ .endpoint_public_access_cidrs | toJson }}
  {{- end }}

  # CloudWatch Logs
  {{- if .enabled_cluster_log_types }}
  cluster_enabled_log_types = {{ .enabled_cluster_log_types | toJson }}
  {{- end }}
  cloudwatch_log_group_retention_in_days = {{ .log_retention_days | default 14 }}

  # EKS Managed Node Groups
  {{- if .node_groups }}
  eks_managed_node_groups = {
    {{- range $nodeGroupKey, $nodeGroupValue := .node_groups }}
    {{ $nodeGroupKey }} = {
      min_size     = {{ .min_size | default 1 }}
      max_size     = {{ .max_size | default 4 }}
      desired_size = {{ .desired_size | default 2 }}

      instance_types = {{ .instance_types | default `["t3.medium"]` | toJson }}
      ami_type       = "{{ .ami_type | default "AL2_x86_64" }}"
      capacity_type  = "{{ .capacity_type | default "ON_DEMAND" }}"
      disk_size      = {{ .disk_size | default 20 }}

      {{- if .labels }}
      labels = {
        {{- range $labelKey, $labelValue := .labels }}
        {{ $labelKey }} = "{{ $labelValue }}"
        {{- end }}
      }
      {{- end }}

      {{- if .taints }}
      taints = {
        {{- range $taintIndex, $taint := .taints }}
        {{ $taintIndex }} = {
          key    = "{{ $taint.key }}"
          value  = "{{ $taint.value }}"
          effect = "{{ $taint.effect }}"
        }
        {{- end }}
      }
      {{- end }}

      {{- if .remote_access }}
      remote_access = {
        {{- if .remote_access.ec2_ssh_key }}
        ec2_ssh_key = "{{ .remote_access.ec2_ssh_key }}"
        {{- end }}
        {{- if .remote_access.source_security_group_ids }}
        source_security_group_ids = {{ .remote_access.source_security_group_ids | toJson }}
        {{- end }}
      }
      {{- end }}
    }
    {{- end }}
  }
  {{- end }}

  # Fargate Profiles
  {{- if .fargate_profiles }}
  fargate_profiles = {
    {{- range $fargateKey, $fargateValue := .fargate_profiles }}
    {{ $fargateKey }} = {
      name = "${local.project_prefix}-{{ $key }}-{{ $fargateKey }}"
      selectors = [
        {
          namespace = "{{ .namespace }}"
          {{- if .labels }}
          labels = {
            {{- range $labelKey, $labelValue := .labels }}
            {{ $labelKey }} = "{{ $labelValue }}"
            {{- end }}
          }
          {{- end }}
        }
      ]
    }
    {{- end }}
  }
  {{- end }}

  # EKS Addons
  {{- if .addons }}
  cluster_addons = {
    {{- range $addonKey, $addonValue := .addons }}
    {{ $addonKey }} = {
      addon_version            = "{{ .version | default "latest" }}"
      resolve_conflicts        = "{{ .resolve_conflicts | default "OVERWRITE" }}"
      {{- if .service_account_role_arn }}
      service_account_role_arn = "{{ .service_account_role_arn }}"
      {{- end }}
    }
    {{- end }}
  }
  {{- end }}

  # IRSA
  enable_irsa = true

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