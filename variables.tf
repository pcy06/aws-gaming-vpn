variable "aws_region" {
  description = "AWS region for resources and Global Accelerator endpoint group."
  type        = string
  default     = "us-west-1"
}

variable "name_prefix" {
  description = "Name prefix for all resources."
  type        = string
  default     = "gaming-vpn"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC."
  type        = string
  default     = "10.50.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet."
  type        = string
  default     = "10.50.1.0/24"
}

variable "vpn_cidr" {
  description = "CIDR block used by WireGuard tunnel."
  type        = string
  default     = "10.77.0.0/24"
}

variable "wireguard_port" {
  description = "WireGuard UDP port."
  type        = number
  default     = 51820
}

variable "client_allowed_ips" {
  description = "Allowed IP ranges routed via VPN on the client."
  type        = string
  default     = "0.0.0.0/0, ::/0"
}

variable "client_dns_servers" {
  description = "DNS servers written to the client WireGuard config."
  type        = string
  default     = "1.1.1.1, 8.8.8.8"
}

variable "persistent_keepalive" {
  description = "PersistentKeepalive value for the client peer."
  type        = number
  default     = 25
}

variable "ssh_ingress_cidrs" {
  description = "Allowed source CIDRs for SSH access."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_rotation_token" {
  description = "Change this value to force local WireGuard key regeneration."
  type        = string
  default     = "v1"
}
