output "ec2_ip" {
  value = module.ec2[*].instance_public_ip
}