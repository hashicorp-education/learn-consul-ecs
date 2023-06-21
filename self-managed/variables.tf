################################################################################
# VPC
################################################################################

variable "name" {
  description = "Tutorial name"
  type        = string
  default     = "learn-consul-"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

################################################################################
# Consul
################################################################################

variable "consul_version" {
  type        = string
  description = "The Consul version"
  default     = "v1.16.0"
}

variable "chart_version" {
  type        = string
  description = "The Consul Helm chart version to use"
  default     = "1.1.2"
}

variable "api_gateway_version" {
  type        = string
  description = "The Consul API gateway CRD version to use"
  default     = "0.5.1"
}

variable "datacenter" {
  type        = string
  description = "The name of the Consul datacenter that client agents should register as"
  default     = "dc1"
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

variable "consul_cluster_addr" {
  type        = string
  description = "The network address of your Consul cluster."
  default = "https://dc1.private.consul.98a0dcc3-5473-4e4d-a28e-6c343c498530.aws.hashicorp.cloud"
}