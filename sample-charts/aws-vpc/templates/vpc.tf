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

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-igw"
    }
  )
}

{{- range .vpc.subnets }}
resource "aws_subnet" "{{ .type }}_{{ .availability_zone | replace "-" "_" }}" {
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

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "{{ .project.name }}-{{ .project.environment }}-public-rt"
    }
  )
}

# Public Route Table Associations
{{- range .vpc.subnets }}
{{- if eq .type "public" }}
resource "aws_route_table_association" "public_{{ .availability_zone | replace "-" "_" }}" {
  subnet_id      = aws_subnet.{{ .type }}_{{ .availability_zone | replace "-" "_" }}.id
  route_table_id = aws_route_table.public.id
}
{{- end }}
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
  depends_on = [aws_internet_gateway.main]
}

{{- $firstPublicSubnet := "" }}
{{- range .vpc.subnets }}
{{- if and (eq .type "public") (eq $firstPublicSubnet "") }}
{{- $firstPublicSubnet = printf "%s_%s" .type (.availability_zone | replace "-" "_") }}
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.{{ $firstPublicSubnet }}.id

  tags = merge(
    local.tags,
    {
      Name = "{{ $.project.name }}-{{ $.project.environment }}-nat"
    }
  )
  depends_on = [aws_internet_gateway.main]
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    local.tags,
    {
      Name = "{{ $.project.name }}-{{ $.project.environment }}-private-rt"
    }
  )
}

# Private Route Table Associations
{{- range $.vpc.subnets }}
{{- if eq .type "private" }}
resource "aws_route_table_association" "private_{{ .availability_zone | replace "-" "_" }}" {
  subnet_id      = aws_subnet.{{ .type }}_{{ .availability_zone | replace "-" "_" }}.id
  route_table_id = aws_route_table.private.id
}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
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