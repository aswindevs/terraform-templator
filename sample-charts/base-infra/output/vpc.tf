
module "vpc_prime" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "5.0.0"
  name                 = "${local.project_prefix}-prime"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-west-2a","us-west-2b","us-west-2c"]
  private_subnets      = ["10.0.2.0/24","10.0.3.0/24"]
  public_subnets       = ["10.0.1.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true
}