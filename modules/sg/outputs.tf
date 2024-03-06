output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "frontend_sg_id" {
  value = aws_security_group.frontend_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "redis_sg_id" {
  value = aws_security_group.redis_sg.id
}