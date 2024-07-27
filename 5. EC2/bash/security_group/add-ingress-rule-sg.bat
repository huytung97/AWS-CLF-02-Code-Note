aws ec2 authorize-security-group-ingress ^
  --group-id sg-05385fe5f06ff5211 ^
  --protocol tcp ^
  --port 22 ^
  --cidr 42.113.60.172/32

aws ec2 authorize-security-group-ingress ^
  --group-id sg-05385fe5f06ff5211 ^
  --protocol tcp ^
  --port 80 ^
  --cidr 42.113.60.172/32