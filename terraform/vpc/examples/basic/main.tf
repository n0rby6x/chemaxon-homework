provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"

  name   = "hw-vpc-example"
  region = var.region

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  # true = 1 shared NAT Gateway (cheaper). Set to false for HA (1 per AZ).
  single_nat_gateway = true

  tags = {
    Project     = "devops-homework"
    Environment = "example"
    ManagedBy   = "terraform"
  }
}
