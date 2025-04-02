# Base Infrastructure Chart

This chart provides a comprehensive base infrastructure setup for AWS, including VPC, ECS, ECR, and RDS resources.

## Chart Structure

```
base-infra/
├── Chart.yaml          # Chart metadata and dependencies
├── values.yaml         # Default configuration values
├── templates/          # Template files
│   ├── provider.tf    # AWS provider configuration
│   ├── locals.tf      # Local variables and tags
│   ├── vpc.tf         # VPC module configuration
│   ├── ecs.tf         # ECS and ECR configuration
│   └── rds.tf         # RDS configuration
└── README.md          # This file
```

## Features

### VPC Configuration
- Configurable CIDR block
- Public and private subnets
- NAT Gateway support
- VPN Gateway support
- DNS support
- Consistent tagging

### ECS Configuration
- Fargate cluster setup
- Container insights enabled
- Multiple capacity providers (FARGATE, FARGATE_SPOT)
- CloudWatch logging

### ECR Configuration
- Multiple repository support
- Image tag mutability settings
- Scan on push enabled
- Lifecycle policies for cleanup
- Consistent tagging

### RDS Configuration
- Optional PostgreSQL database
- Configurable instance class
- Private subnet placement
- Automated backups
- Consistent tagging

## Configuration

The chart can be configured through the `values.yaml` file. Here are the main configuration options:

### Project Settings
- `project.name`: Name of the project
- `project.environment`: Environment (e.g., dev, prod)
- `project.region`: AWS region

### Provider Settings
- `provider.aws.region`: AWS region
- `provider.aws.profile`: AWS profile name

### VPC Settings
- `vpc.enable`: Enable/disable VPC creation
- `vpc.cidr`: VPC CIDR block
- `vpc.enable_nat_gateway`: Enable/disable NAT Gateway
- `vpc.enable_vpn`: Enable/disable VPN Gateway
- `vpc.subnets`: List of subnet configurations

### ECS Settings
- `ecs.enable`: Enable/disable ECS cluster
- `ecs.cluster_name`: Name of the ECS cluster
- `ecs.container_insights`: Enable container insights
- `ecs.capacity_providers`: List of capacity providers

### ECR Settings
- `ecr.enable`: Enable/disable ECR repositories
- `ecr.repositories`: List of repository configurations

### RDS Settings
- `rds.enable`: Enable/disable RDS instance
- `rds.engine`: Database engine
- `rds.instance_class`: Instance type
- `rds.allocated_storage`: Storage size
- `rds.db_name`: Database name
- `rds.username`: Database username
- `rds.password`: Database password

### Tags
- `tags`: Key-value pairs for resource tagging

## Usage

To render this chart:

```bash
terraform-templator render chart base-infra --values values.yaml --output output/
```

## Dependencies

This chart uses the following Terraform modules:
- terraform-aws-modules/vpc/aws (v5.0.0)
- terraform-aws-modules/ecs/aws (v5.0.0)
- terraform-aws-modules/ecr/aws (v1.6.0)
- terraform-aws-modules/rds/aws (v6.0.0)

## Security Considerations

1. RDS passwords should be provided via environment variables or secrets management
2. VPC endpoints can be added for additional security
3. Security groups and NACLs can be customized
4. KMS encryption can be enabled for sensitive resources 