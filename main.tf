terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "~> 0.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  wireguard_dir       = "${path.root}/generated"
  client_config_path  = "${local.wireguard_dir}/gaming-vpn.conf"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  target_az = contains(data.aws_availability_zones.available.names, var.local_zone_name) ? var.local_zone_name : data.aws_availability_zones.available.names[0]
}

resource "null_resource" "prepare_local_output_dir" {
  provisioner "local-exec" {
    command     = "mkdir -p ${local.wireguard_dir}"
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "wireguard_asymmetric_key" "server" {
  bind = var.key_rotation_token
}

resource "wireguard_asymmetric_key" "client" {
  bind = var.key_rotation_token
}

resource "aws_vpc" "vpn" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "vpn" {
  vpc_id = aws_vpc.vpn.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_subnet" "vpn" {
  vpc_id                  = aws_vpc.vpn.id
  cidr_block              = var.subnet_cidr
  availability_zone       = local.target_az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-subnet"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpn.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpn.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.vpn.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "wireguard" {
  name        = "${var.name_prefix}-wireguard-sg"
  description = "WireGuard and SSH access"
  vpc_id      = aws_vpc.vpn.id

  ingress {
    description = "WireGuard UDP"
    from_port   = var.wireguard_port
    to_port     = var.wireguard_port
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-wireguard-sg"
  }
}

data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "wireguard" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.vpn.id
  vpc_security_group_ids      = [aws_security_group.wireguard.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/templates/user_data.sh.tftpl", {
    wireguard_port     = var.wireguard_port
    server_private_key = wireguard_asymmetric_key.server.private_key
    client_public_key  = wireguard_asymmetric_key.client.public_key
    vpn_cidr           = var.vpn_cidr
    server_vpn_ip      = cidrhost(var.vpn_cidr, 1)
    client_vpn_ip      = cidrhost(var.vpn_cidr, 2)
  })

  tags = {
    Name = "${var.name_prefix}-wireguard"
  }
}

resource "aws_eip" "wireguard" {
  domain   = "vpc"
  instance = aws_instance.wireguard.id

  tags = {
    Name = "${var.name_prefix}-wireguard-eip"
  }
}

resource "aws_globalaccelerator_accelerator" "vpn" {
  name            = "${var.name_prefix}-ga"
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "wireguard" {
  accelerator_arn = aws_globalaccelerator_accelerator.vpn.id
  protocol        = "UDP"

  port_range {
    from_port = var.wireguard_port
    to_port   = var.wireguard_port
  }
}

resource "aws_globalaccelerator_endpoint_group" "wireguard" {
  listener_arn          = aws_globalaccelerator_listener.wireguard.id
  endpoint_group_region = var.aws_region

  endpoint_configuration {
    endpoint_id = aws_instance.wireguard.id
    weight      = 128
  }
}

resource "local_file" "gaming_vpn_conf" {
  filename = local.client_config_path
  content = templatefile("${path.module}/templates/gaming-vpn.conf.tftpl", {
    client_private_key    = wireguard_asymmetric_key.client.private_key
    server_public_key     = wireguard_asymmetric_key.server.public_key
    endpoint              = "${aws_globalaccelerator_accelerator.vpn.dns_name}:${var.wireguard_port}"
    client_address        = "${cidrhost(var.vpn_cidr, 2)}/32"
    dns_servers           = var.client_dns_servers
    allowed_ips           = var.client_allowed_ips
    persistent_keepalive  = var.persistent_keepalive
  })

  depends_on = [
    null_resource.prepare_local_output_dir,
    aws_globalaccelerator_endpoint_group.wireguard
  ]
}
