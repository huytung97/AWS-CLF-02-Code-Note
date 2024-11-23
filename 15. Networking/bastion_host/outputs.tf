output "public_ec2_ip_addr" {
  value = module.ec2.public_ec2_ip
}

output "private_ec2_ip_addr" {
  value = module.ec2.private_instances_ip
}