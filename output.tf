output "prom_graf_ip" {
  value = aws_instance.prom_graf_instance.public_ip
}

output "target_ip" {
  value = aws_instance.target_instance.public_ip
}