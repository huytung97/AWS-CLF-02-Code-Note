output "public_ec2_ip" {
  value = aws_instance.public_instance.public_ip
}