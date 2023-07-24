################################################################################
# VPC
################################################################################

variable "name" {
  description = "Tutorial name"
  type        = string
  default     = "learn-consul"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

################################################################################
# HCP Consul
################################################################################

variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "learn-consul-ecs"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-west-2"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "learn-consul-ecs-hvn"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}


################################################################################
# EKS Consul
################################################################################

variable "consul_version" {
  type        = string
  description = "The Consul version"
  default     = "1.16.0"
}

variable "chart_version" {
  type        = string
  description = "The Consul Helm chart version to use"
  default     = "1.2.0"
}

################################################################################
# Other
################################################################################

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  name = "${var.name}-${random_string.suffix.result}"
}