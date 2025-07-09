locals {
  name           = "my-project"
  environment    = "dev"
  region         = "us-west-2"
  project_prefix = "${local.name}-${local.environment}-${local.region_code[local.region]}"
  tags = {
    Environment  = "dev"
    ManagedBy    = "terraform-templator"
    Project      = "my-project"
  }

  vpc_tags = merge(
    local.tags,
    {
      Name = "${local.name}-vpc"
    }
  )

  subnet_tags = {
    "public_us-west-2a" = merge(
      local.tags,
      {
        Name = "${local.name}-public-us-west-2a"
        Type = "public"
      }
    )
    "private_us-west-2b" = merge(
      local.tags,
      {
        Name = "${local.name}-private-us-west-2b"
        Type = "private"
      }
    )
    "private_us-west-2c" = merge(
      local.tags,
      {
        Name = "${local.name}-private-us-west-2c"
        Type = "private"
      }
    )
  }
  eks_tags = merge(
    local.tags,
    {
      Name = "${local.name}-eks-cluster"
    }
  )
  ecs_tags = merge(
    local.tags,
    {
      Name = "${local.name}-ecs-cluster"
    }
  )

  region_code = {
    us-east-2      = "oh" # Ohio
    us-east-1      = "nv" # US East (N. Virginia)
    us-west-1      = "ca" # N. California
    us-west-2      = "or" # US West (Oregon)
    ap-east-1      = "hk" # Hong Kong
    ap-south-1     = "mb" # Asia Pacific (Mumbai)
    ap-northeast-3 = "os" # Osaka-Local
    ap-northeast-2 = "se" # Asia Pacific (Seoul)
    ap-southeast-1 = "sg" # Singapore
    ap-southeast-2 = "sd" # Asia Pacific (Sydney)
    ap-northeast-1 = "tk" # Tokyo
    ca-central-1   = "cn" # Canada (Central)
    eu-central-1   = "ff" # Frankfurt
    eu-west-1      = "ie" # Europe (Ireland)
    eu-west-2      = "ld" # London
    eu-west-3      = "pr" # Europe (Paris)
    eu-north-1     = "st" # Stockholm
    me-south-1     = "bh" # Middle East (Bahrain)
    sa-east-1      = "sp" # São Paulo
  }
} 