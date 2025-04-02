# AWS VPC Chart

This chart provides a template for creating an AWS VPC with configurable subnets, NAT Gateway, and VPN Gateway.

## Chart Structure

```
aws-vpc/
├── Chart.yaml          # Chart metadata and dependencies
├── values.yaml         # Default configuration values
├── templates/          # Template files
│   ├── vpc.tf         # VPC and related resources
│   └── locals.tf      # Local variables and tags
└── README.md          # This file
```

## Configuration

The chart can be configured through the `values.yaml` file. Here are the main configuration options:

### Project Settings
- `project.name`: Name of the project
- `project.environment`: Environment (e.g., dev, prod)
- `project.region`: AWS region

### VPC Configuration
- `vpc.enable`: Enable/disable VPC creation
- `vpc.cidr`: VPC CIDR block
- `vpc.enable_nat_gateway`: Enable/disable NAT Gateway
- `vpc.enable_vpn`: Enable/disable VPN Gateway
- `vpc.subnets`: List of subnet configurations
  - `cidr`: Subnet CIDR block
  - `type`: Subnet type (public/private)
  - `availability_zone`: AWS availability zone

### Tags
- `tags`: Key-value pairs for resource tagging

## Usage

To render this chart:

```bash
terraform-templator render chart aws-vpc --values values.yaml --output output/
```

## Features

- Configurable VPC with public and private subnets
- Optional NAT Gateway for private subnet internet access
- Optional VPN Gateway for secure remote access
- Consistent resource naming and tagging
- Environment-aware configuration 