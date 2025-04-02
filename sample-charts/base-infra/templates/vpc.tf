{{- if .vpc -}}
{{- range $key, $value := .vpc }}
module "vpc_{{ $key }}" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = local.name
  cidr = "{{ .vpc.cidr }}"

  azs             = [{{- range .vpc.subnets }}"{{ .availability_zone }}",{{- end }}]
  private_subnets = [{{- range .vpc.subnets }}{{- if eq .type "private" }}"{{ .cidr }}",{{- end }}{{- end }}]
  public_subnets  = [{{- range .vpc.subnets }}{{- if eq .type "public" }}"{{ .cidr }}",{{- end }}{{- end }}]

  enable_nat_gateway = {{ .vpc.enable_nat_gateway }}
  single_nat_gateway = true

  enable_vpn_gateway = {{ .vpc.enable_vpn }}

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    {{- range .vpc.subnets }}
    {{- if eq .type "public" }}
    "{{ .availability_zone }}" = local.subnet_tags["public_{{ .availability_zone }}"]
    {{- end }}
    {{- end }}
  }

  private_subnet_tags = {
    {{- range .vpc.subnets }}
    {{- if eq .type "private" }}
    "{{ .availability_zone }}" = local.subnet_tags["private_{{ .availability_zone }}"]
    {{- end }}
    {{- end }}
  }

  tags = local.vpc_tags
}
{{- end }}
{{- end }}