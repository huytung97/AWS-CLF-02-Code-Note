Commands:
terraform plan -var-file="env.tfvars" -out tfplan.out
terraform apply tfplan.out
terraform destroy --var-file=env.tfvars --auto-approve