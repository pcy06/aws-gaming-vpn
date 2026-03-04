output "wireguard_server_instance_id" {
  value       = aws_instance.wireguard.id
  description = "WireGuard EC2 instance ID."
}

output "wireguard_server_public_ip" {
  value       = aws_eip.wireguard.public_ip
  description = "Elastic IP assigned to WireGuard server."
}

output "global_accelerator_dns_name" {
  value       = aws_globalaccelerator_accelerator.vpn.dns_name
  description = "Global Accelerator DNS name to use as WireGuard endpoint."
}

output "global_accelerator_static_ips" {
  value       = aws_globalaccelerator_accelerator.vpn.ip_sets[*].ip_addresses
  description = "Static Anycast IPv4 addresses provided by Global Accelerator."
}

output "client_config_path" {
  value       = local_file.gaming_vpn_conf.filename
  description = "Path to generated local WireGuard client config file."
}
