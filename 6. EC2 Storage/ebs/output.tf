output "ec2-instance-public-ip" {
  value = aws_instance.chap-6-ec2.public_ip 
}