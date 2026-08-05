provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {
  # Exclude local availability zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  tenant             = var.tenant
  kubernetes_version = var.kubernetes_version
  region             = var.region

  vpc_cidr           = var.vpc_cidr

  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Tenant      = local.tenant
    Environment = "${var.environment}"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                   = "${local.tenant}-eks"
  kubernetes_version     = local.kubernetes_version

  endpoint_public_access = true

  enable_irsa        = false

  enable_cluster_creator_admin_permissions = true

  compute_config = {
    enabled       = true
    node_pools    = ["general-purpose"]
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.tenant}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  private_subnet_names = [for k, v in local.azs : "${local.tenant}-subnet-${v}-private"]
  public_subnet_names  = [for k, v in local.azs : "${local.tenant}-subnet-${v}-public"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}
