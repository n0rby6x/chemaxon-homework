variable "name" {
  description = "Name prefix used to tag/name every resource created by this module."
  type        = string
}

variable "region" {
  description = "AWS region the VPC is deployed in. Needed to build the S3 VPC endpoint service name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the 2 public subnets (one per AZ). Must contain exactly 2 entries."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnet CIDRs are required (one per AZ)."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the 2 private subnets (one per AZ). Must contain exactly 2 entries."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly 2 private subnet CIDRs are required (one per AZ)."
  }
}

variable "single_nat_gateway" {
  description = <<-EOT
    true  = 1 shared NAT Gateway for both private subnets (cheaper, ~half
            the cost, but the NAT gateway's AZ becomes a single point of
            failure for outbound traffic).
    false = 1 NAT Gateway per AZ (highly available, ~2x NAT Gateway cost).
  EOT
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
