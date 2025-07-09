
module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${local.project_prefix}-cluster"
  cluster_version = "1.28"

  # VPC configuration
  vpc_id                          = module.vpc_prime.vpc_id
  subnet_ids                      = concat(module.vpc_prime.private_subnets, module.vpc_prime.public_subnets)
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # CloudWatch Logs
  cluster_enabled_log_types = ["api","audit","authenticator","controllerManager","scheduler"]
  cloudwatch_log_group_retention_in_days = 14

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    default = {
      min_size     = 1
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.medium"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
      labels = {
        Environment = "dev"
        NodeGroup = "default"
      }
    }
    spot = {
      min_size     = 1
      max_size     = 3
      desired_size = 1

      instance_types = ["t3.medium","t3.large"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"
      disk_size      = 20
      labels = {
        CapacityType = "spot"
        Environment = "dev"
        NodeGroup = "spot"
      }
    }
  }

  # Fargate Profiles

  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      addon_version            = "latest"
      resolve_conflicts        = "OVERWRITE"
    }
    coredns = {
      addon_version            = "latest"
      resolve_conflicts        = "OVERWRITE"
    }
    kube-proxy = {
      addon_version            = "latest"
      resolve_conflicts        = "OVERWRITE"
    }
    vpc-cni = {
      addon_version            = "latest"
      resolve_conflicts        = "OVERWRITE"
    }
  }

  # IRSA
  enable_irsa = true

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster"
    }
  )
} 