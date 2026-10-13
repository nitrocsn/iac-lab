output "ip_privee" {
  description = "IP privees des serveurs web"
  value       = aws_instance.vm[*].private_ip
}
