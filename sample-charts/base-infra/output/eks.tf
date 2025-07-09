
# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${local.project_prefix}-cluster"
  role_arn = aws_iam_role.eks_cluster_cluster.arn
  version  = "1.28"

  vpc_config {
    subnet_ids              = concat(module.vpc_prime.private_subnets, module.vpc_prime.public_subnets)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }
  enabled_cluster_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_cluster,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller_cluster,
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster"
    }
  )
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_cluster" {
  name = "${local.project_prefix}-cluster-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-cluster"
    }
  )
}

# EKS Cluster Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_cluster.name
}

# OIDC Provider for Service Accounts
data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-oidc"
    }
  )
}
# EKS Node Group - default
resource "aws_eks_node_group" "cluster_default" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${local.project_prefix}-cluster-default"
  node_role_arn   = aws_iam_role.eks_node_group_cluster.arn
  subnet_ids      = module.vpc_prime.private_subnets
  
  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }
  labels = {
    "Environment" = "dev"
    "NodeGroup" = "default"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_cluster,
    aws_iam_role_policy_attachment.eks_cni_policy_cluster,
    aws_iam_role_policy_attachment.eks_container_registry_policy_cluster,
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-default"
    }
  )
}
# EKS Node Group - spot
resource "aws_eks_node_group" "cluster_spot" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${local.project_prefix}-cluster-spot"
  node_role_arn   = aws_iam_role.eks_node_group_cluster.arn
  subnet_ids      = module.vpc_prime.private_subnets
  
  instance_types = ["t3.medium","t3.large"]
  ami_type       = "AL2_x86_64"
  capacity_type  = "SPOT"
  disk_size      = 20

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }
  labels = {
    "CapacityType" = "spot"
    "Environment" = "dev"
    "NodeGroup" = "spot"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_cluster,
    aws_iam_role_policy_attachment.eks_cni_policy_cluster,
    aws_iam_role_policy_attachment.eks_container_registry_policy_cluster,
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-spot"
    }
  )
}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_cluster" {
  name = "${local.project_prefix}-cluster-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-node-group"
    }
  )
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_cluster.name
}
# EKS Add-on - aws-ebs-csi-driver
resource "aws_eks_addon" "cluster_aws-ebs-csi-driver" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "latest"
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-aws-ebs-csi-driver"
    }
  )
}
# EKS Add-on - coredns
resource "aws_eks_addon" "cluster_coredns" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "coredns"
  addon_version            = "latest"
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-coredns"
    }
  )
}
# EKS Add-on - kube-proxy
resource "aws_eks_addon" "cluster_kube-proxy" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "kube-proxy"
  addon_version            = "latest"
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-kube-proxy"
    }
  )
}
# EKS Add-on - vpc-cni
resource "aws_eks_addon" "cluster_vpc-cni" {
  cluster_name             = aws_eks_cluster.cluster.name
  addon_name               = "vpc-cni"
  addon_version            = "latest"
  resolve_conflicts        = "OVERWRITE"

  depends_on = [
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-vpc-cni"
    }
  )
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${local.project_prefix}-cluster/cluster"
  retention_in_days = 14

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-logs"
    }
  )
} 