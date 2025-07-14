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

### EKS Configuration
- **Module-based**: Uses `terraform-aws-modules/eks/aws` for consistency
- Kubernetes cluster with configurable version
- EKS managed node groups with different instance types and capacity types
- Support for both ON_DEMAND and SPOT instances
- Node group auto-scaling configuration
- IAM roles and service accounts (IRSA) automatically configured
- Essential add-ons (VPC CNI, CoreDNS, kube-proxy, EBS CSI driver)
- CloudWatch logging with configurable retention
- Optional Fargate profiles for serverless workloads
- Consistent tagging and naming conventions

### ECS Configuration
- **Module-based**: Uses `terraform-aws-modules/ecs/aws` for consistency
- Fargate cluster with configurable capacity providers
- Container insights support
- CloudWatch logging with configurable retention
- Service discovery namespace support
- Auto scaling configuration with managed scaling
- Execute command configuration for debugging

### RDS Configuration
- **Module-based**: Uses `terraform-aws-modules/rds/aws` for consistency
- PostgreSQL database support
- Configurable instance class and storage
- Private subnet placement for security
- Automated backups and maintenance
- Consistent tagging and naming

*Note: ECR support is planned but not yet implemented.*

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

### EKS Settings
- `eks.enable`: Enable/disable EKS cluster
- `eks.cluster.cluster_version`: Kubernetes version (e.g., "1.28")
- `eks.cluster.endpoint_private_access`: Enable private API endpoint access
- `eks.cluster.endpoint_public_access`: Enable public API endpoint access
- `eks.cluster.endpoint_public_access_cidrs`: CIDR blocks for public access
- `eks.cluster.enabled_cluster_log_types`: CloudWatch log types to enable
- `eks.cluster.log_retention_days`: CloudWatch log retention in days
- `eks.cluster.node_groups`: Node group configurations
  - `instance_types`: List of EC2 instance types
  - `ami_type`: AMI type (AL2_x86_64, AL2_ARM_64, etc.)
  - `capacity_type`: Capacity type (ON_DEMAND, SPOT)
  - `disk_size`: EBS disk size in GB
  - `desired_size`: Desired number of nodes
  - `max_size`: Maximum number of nodes
  - `min_size`: Minimum number of nodes
  - `labels`: Kubernetes labels for nodes
  - `taints`: Kubernetes taints for nodes
  - `remote_access`: SSH access configuration
- `eks.cluster.addons`: EKS add-ons configuration
  - `version`: Add-on version
  - `resolve_conflicts`: Conflict resolution strategy
- `eks.cluster.fargate_profiles`: Fargate profile configurations
  - `namespace`: Kubernetes namespace
  - `labels`: Pod selection labels

### ECS Settings
- `ecs.enable`: Enable/disable ECS cluster
- `ecs.cluster.container_insights`: Enable container insights
- `ecs.cluster.capacity_providers`: List of capacity providers (FARGATE, FARGATE_SPOT)
- `ecs.cluster.default_capacity_provider_strategy`: Capacity provider strategy configuration
- `ecs.cluster.log_retention_days`: CloudWatch log retention in days
- `ecs.cluster.service_discovery`: Service discovery namespace configuration
- `ecs.cluster.autoscaling`: Enable autoscaling configuration

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

## Component Enable/Disable

Each infrastructure component can be individually enabled or disabled:

```yaml
# Enable all components
vpc:
  enable: true
  
eks:
  enable: true
  
ecs:
  enable: true
  
rds:
  enable: true
```

```yaml
# Disable specific components
vpc:
  enable: false  # VPC template will be empty
  
eks:
  enable: true   # EKS template will render normally
  
ecs:
  enable: false  # ECS template will be empty
  
rds:
  enable: false  # RDS template will be empty
```

## Dependencies

This chart uses the following Terraform modules and providers:
- **terraform-aws-modules/vpc/aws** (v5.0.0) - VPC and networking resources
- **terraform-aws-modules/eks/aws** (v19.0.0) - EKS cluster and managed node groups
- **terraform-aws-modules/ecs/aws** (v5.0.0) - ECS cluster with Fargate support
- **terraform-aws-modules/rds/aws** (v6.0.0) - RDS database instances
- **hashicorp/tls provider** - TLS certificate data for EKS OIDC

All infrastructure components use well-maintained, community-tested Terraform modules for consistency, security, and best practices.

## Security Considerations

1. EKS cluster endpoints can be configured for private-only access
2. Node groups are deployed in private subnets by default
3. EKS service accounts can use IAM roles via OIDC
4. RDS passwords should be provided via environment variables or secrets management
5. VPC endpoints can be added for additional security
6. Security groups and NACLs can be customized
7. KMS encryption can be enabled for sensitive resources
8. ECS task roles should follow principle of least privilege
9. EKS add-ons should be kept up to date for security patches 