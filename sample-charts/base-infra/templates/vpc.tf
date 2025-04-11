{{- if .vpc -}}
{{- range $key, $value := .vpc }}
module "vpc_{{ $key }}" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.0.0"
  name                 = "${local.project_prefix}-{{ $key }}"
  cidr                 = "{{ .cidr }}"
  azs                  = [{{- $first := true -}}{{- range .subnets -}}{{ if not $first -}}, {{- end -}}"{{ .availability_zone }}"{{- $first = false -}}{{- end -}}]
  private_subnets      = [{{- $first := true -}}{{- range .subnets -}}{{- if eq .type "private" -}}{{ if not $first -}}, {{- end -}}"{{ .cidr }}"{{- $first = false -}}{{- end -}}{{- end -}}]
  public_subnets       = [{{- $first := true -}}{{- range .subnets -}}{{- if eq .type "public" -}}{{ if not $first -}}, {{- end -}}"{{ .cidr }}"{{- $first = false -}}{{- end -}}{{- end -}}]
  enable_nat_gateway   = {{ .enable_nat_gateway }}
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}
{{- end }}
{{- end }}