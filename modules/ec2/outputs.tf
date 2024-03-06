output "backend_public_ips" {
  value = aws_instance.backend[*].public_ip
}

output "frontend_public_ips" {
  value = aws_instance.frontend[*].public_ip
}

output "backend_private_ips" {
  value = aws_instance.backend[*].private_ip
}

output "frontend_private_ips" {
  value = aws_instance.frontend[*].private_ip
}

output "backend_id" {
  value = aws_instance.backend[*].id
}

output "frontend_id" {
  value = aws_instance.frontend[*].id
}