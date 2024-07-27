aws iam create-instance-profile --instance-profile-name MyEC2InstanceProfile
aws iam add-role-to-instance-profile --role-name EC2_listUsers --instance-profile-name MyEC2InstanceProfile
aws ec2 associate-iam-instance-profile --instance-id i-04ee1c2a6bc548f48 --iam-instance-profile Name=MyEC2InstanceProfile