{{- if .vpc.enable }}
resource "aws_vpc" "main" {
  cidr_block           = "{{ .vpc.cidr }}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-vpc"
    }
  )
}

{{- range .vpc.subnets }}
resource "aws_subnet" "{{ .type }}_{{ .availability_zone }}" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "{{ .cidr }}"
  availability_zone       = "{{ .availability_zone }}"
  map_public_ip_on_launch = {{ eq .type "public" }}

  tags = merge(
    local.tags,
    {
      Name = "{{ $.project.name }}-{{ $.project.environment }}-{{ .type }}-{{ .availability_zone }}"
      Type = "{{ .type }}"
    }
  )
}
{{- end }}

{{- if .vpc.enable_nat_gateway }}
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-nat-eip"
    }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_us-west-2a.id

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-nat"
    }
  )
}
{{- end }}

{{- if .vpc.enable_vpn }}
resource "aws_customer_gateway" "main" {
  bgp_asn    = 65000
  ip_address = "172.83.124.10"
  type       = "ipsec.1"

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-cgw"
    }
  )
}

resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-vgw"
    }
  )
}

resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.main.id
  type               = "ipsec.1"
  static_routes_only = true

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-vpn"
    }
  )
}
{{- end }}
{{- end }} 