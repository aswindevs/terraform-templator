{{- if .eks.enable -}}
{{- range $key, $value := .eks }}
{{- if ne $key "enable" }}
# EKS Cluster
resource "aws_eks_cluster" "{{ $key }}" {
  name     = "${local.project_prefix}-{{ $key }}"
  role_arn = aws_iam_role.eks_cluster_{{ $key }}.arn
  version  = "{{ .cluster_version | default "1.28" }}"

  vpc_config {
    subnet_ids              = concat(module.vpc_prime.private_subnets, module.vpc_prime.public_subnets)
    endpoint_private_access = {{ .endpoint_private_access | default "true" }}
    endpoint_public_access  = {{ .endpoint_public_access | default "true" }}
    {{- if .endpoint_public_access_cidrs }}
    public_access_cidrs     = {{ .endpoint_public_access_cidrs | toJson }}
    {{- end }}
  }

  {{- if .enabled_cluster_log_types }}
  enabled_cluster_log_types = {{ .enabled_cluster_log_types | toJson }}
  {{- end }}

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_{{ $key }},
    aws_iam_role_policy_attachment.eks_vpc_resource_controller_{{ $key }},
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}"
    }
  )
}

# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-cluster"

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
      Name = "${local.project_prefix}-{{ $key }}-cluster"
    }
  )
}

# EKS Cluster Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_{{ $key }}.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_{{ $key }}.name
}

# OIDC Provider for Service Accounts
data "tls_certificate" "eks_{{ $key }}" {
  url = aws_eks_cluster.{{ $key }}.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_{{ $key }}" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_{{ $key }}.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.{{ $key }}.identity[0].oidc[0].issuer

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-oidc"
    }
  )
}

{{- if .node_groups }}
{{- range $nodeGroupKey, $nodeGroupValue := .node_groups }}
# EKS Node Group - {{ $nodeGroupKey }}
resource "aws_eks_node_group" "{{ $key }}_{{ $nodeGroupKey }}" {
  cluster_name    = aws_eks_cluster.{{ $key }}.name
  node_group_name = "${local.project_prefix}-{{ $key }}-{{ $nodeGroupKey }}"
  node_role_arn   = aws_iam_role.eks_node_group_{{ $key }}.arn
  subnet_ids      = module.vpc_prime.private_subnets
  
  instance_types = {{ .instance_types | default `["t3.medium"]` | toJson }}
  ami_type       = "{{ .ami_type | default "AL2_x86_64" }}"
  capacity_type  = "{{ .capacity_type | default "ON_DEMAND" }}"
  disk_size      = {{ .disk_size | default 20 }}

  scaling_config {
    desired_size = {{ .desired_size | default 2 }}
    max_size     = {{ .max_size | default 4 }}
    min_size     = {{ .min_size | default 1 }}
  }

  {{- if .remote_access }}
  remote_access {
    {{- if .remote_access.ec2_ssh_key }}
    ec2_ssh_key = "{{ .remote_access.ec2_ssh_key }}"
    {{- end }}
    {{- if .remote_access.source_security_group_ids }}
    source_security_group_ids = {{ .remote_access.source_security_group_ids | toJson }}
    {{- end }}
  }
  {{- end }}

  {{- if .labels }}
  labels = {
    {{- range $labelKey, $labelValue := .labels }}
    "{{ $labelKey }}" = "{{ $labelValue }}"
    {{- end }}
  }
  {{- end }}

  {{- if .taints }}
  {{- range .taints }}
  taint {
    key    = "{{ .key }}"
    value  = "{{ .value }}"
    effect = "{{ .effect }}"
  }
  {{- end }}
  {{- end }}

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy_{{ $key }},
    aws_iam_role_policy_attachment.eks_cni_policy_{{ $key }},
    aws_iam_role_policy_attachment.eks_container_registry_policy_{{ $key }},
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-{{ $nodeGroupKey }}"
    }
  )
}
{{- end }}

# EKS Node Group IAM Role
resource "aws_iam_role" "eks_node_group_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-node-group"

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
      Name = "${local.project_prefix}-{{ $key }}-node-group"
    }
  )
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_{{ $key }}.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_{{ $key }}.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_{{ $key }}.name
}
{{- end }}

{{- if .addons }}
{{- range $addonKey, $addonValue := .addons }}
# EKS Add-on - {{ $addonKey }}
resource "aws_eks_addon" "{{ $key }}_{{ $addonKey }}" {
  cluster_name             = aws_eks_cluster.{{ $key }}.name
  addon_name               = "{{ $addonKey }}"
  addon_version            = "{{ .version | default "latest" }}"
  resolve_conflicts        = "{{ .resolve_conflicts | default "OVERWRITE" }}"
  {{- if .service_account_role_arn }}
  service_account_role_arn = "{{ .service_account_role_arn }}"
  {{- end }}

  depends_on = [
    {{- if .node_groups }}
    {{- range $nodeGroupKey, $nodeGroupValue := .node_groups }}
    aws_eks_node_group.{{ $key }}_{{ $nodeGroupKey }},
    {{- end }}
    {{- end }}
  ]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-{{ $addonKey }}"
    }
  )
}
{{- end }}
{{- end }}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks_{{ $key }}" {
  name              = "/aws/eks/${local.project_prefix}-{{ $key }}/cluster"
  retention_in_days = {{ .log_retention_days | default 14 }}

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-logs"
    }
  )
}

{{- if .fargate_profiles }}
{{- range $fargateKey, $fargateValue := .fargate_profiles }}
# EKS Fargate Profile - {{ $fargateKey }}
resource "aws_eks_fargate_profile" "{{ $key }}_{{ $fargateKey }}" {
  cluster_name           = aws_eks_cluster.{{ $key }}.name
  fargate_profile_name   = "${local.project_prefix}-{{ $key }}-{{ $fargateKey }}"
  pod_execution_role_arn = aws_iam_role.eks_fargate_{{ $key }}.arn
  subnet_ids             = module.vpc_prime.private_subnets

  selector {
    namespace = "{{ .namespace }}"
    {{- if .labels }}
    labels = {
      {{- range $labelKey, $labelValue := .labels }}
      "{{ $labelKey }}" = "{{ $labelValue }}"
      {{- end }}
    }
    {{- end }}
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-{{ $fargateKey }}"
    }
  )
}
{{- end }}

# EKS Fargate Profile IAM Role
resource "aws_iam_role" "eks_fargate_{{ $key }}" {
  name = "${local.project_prefix}-{{ $key }}-fargate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-{{ $key }}-fargate"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_fargate_policy_{{ $key }}" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate_{{ $key }}.name
}
{{- end }}

{{- end }}
{{- end }}
{{- end }} 