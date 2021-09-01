output "dns_address" {
  value = aws_elb.web.dns_name
}

output "instance_ids" {
  value = aws_instance.web[*].id
}

output "instance_ips" {
  value = aws_instance.web[*].public_ip
}
