
# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${local.project_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  capacity_providers = ["FARGATE","FARGATE_SPOT"]

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster"
    }
  )
}
# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = ["FARGATE","FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 4
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/ecs/${local.project_prefix}-cluster"
  retention_in_days = 14

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-logs"
    }
  )
}
# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "cluster" {
  name        = "myproject.local"
  description = "Service discovery namespace for cluster"
  vpc         = module.vpc_prime.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-discovery"
    }
  )
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_cluster" {
  name = "${local.project_prefix}-cluster-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-task-execution"
    }
  )
}

# Attach ECS Task Execution Role Policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_cluster" {
  role       = aws_iam_role.ecs_task_execution_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_cluster" {
  name = "${local.project_prefix}-cluster-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-task"
    }
  )
}
# Auto Scaling Role
resource "aws_iam_role" "ecs_autoscaling_cluster" {
  name = "${local.project_prefix}-cluster-autoscaling"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster-autoscaling"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_autoscaling_cluster" {
  role       = aws_iam_role.ecs_autoscaling_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSServiceRolePolicy"
} 