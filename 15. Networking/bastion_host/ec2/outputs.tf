output "public_ec2_ip" {
  value = aws_instance.public_instance.public_ip
}

output "private_instances_ip" {
  value = [for instance in aws_instance.private_instances: instance.private_ip]
}