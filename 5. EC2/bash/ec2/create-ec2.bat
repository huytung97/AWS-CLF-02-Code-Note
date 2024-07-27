aws ec2 run-instances ^
  --image-id ami-012c2e8e24e2ae21d ^
  --instance-type t2.micro ^
  --key-name my-key-pair-1 ^
  --security-group-ids sg-05385fe5f06ff5211 ^
  --subnet-id subnet-03ec7b89ba1f7add9 ^
  --region ap-southeast-1
