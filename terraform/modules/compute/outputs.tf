# ==============================================================================
# Compute Module - Outputs
# ==============================================================================

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.moodle.id
}

output "public_ip" {
  description = "IP público da instância"
  value       = aws_instance.moodle.public_ip
}

output "public_dns" {
  description = "DNS público da instância"
  value       = aws_instance.moodle.public_dns
}

output "ec2_security_group_id" {
  description = "ID do Security Group da EC2"
  value       = aws_security_group.ec2.id
}

output "private_ip" {
  description = "IP privado da instância"
  value       = aws_instance.moodle.private_ip
}
