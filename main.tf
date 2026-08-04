## Install OpenTofu
#
#```
#brew install opentofu
#```
#
## Install aws-cli
#```
#curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
#export PATH=$PATH:$HOME/.local/bin
#```
#
## Install KubeCTL
#
#```
#curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.36.2/2026-07-05/bin/darwin/amd64/kubectl
#```
#
## Download Tofu providers
#```
#tofu init
#```
## Plan
#
#```
#```

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
  name               = var.name
  kubernetes_version = var.kubernetes_version
  region             = var.region

  vpc_cidr           = var.vpc_cidr

  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name        = local.name
    Environment = "${var.environment}"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                   = "${local.name}-eks"
  kubernetes_version     = local.kubernetes_version

  #endpoint_public_access = true

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

  #name = local.name
  name = "${local.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

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
