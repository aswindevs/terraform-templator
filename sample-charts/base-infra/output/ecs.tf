
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = "${local.project_prefix}-cluster"

  # Cluster configuration
  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.project_prefix}-cluster"
      }
    }
  }

  # CloudWatch Log Groups
  cloudwatch_log_group_name              = "/aws/ecs/${local.project_prefix}-cluster"
  cloudwatch_log_group_retention_in_days = 14

  # Cluster settings
  cluster_settings = {
    "name"  = "containerInsights"
    "value" = "enabled"
  }
  # Capacity providers
  default_capacity_provider_use_fargate = true
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 1
        base   = 1
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 4
        base   = 0
      }
    }
  }
  # Autoscaling
  autoscaling_capacity_providers = {
    FARGATE = {
      auto_scaling_group_arn         = ""
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
    FARGATE_SPOT = {
      auto_scaling_group_arn         = ""
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }

      default_capacity_provider_strategy = {
        weight = 60
        base   = 20
      }
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.project_prefix}-cluster"
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