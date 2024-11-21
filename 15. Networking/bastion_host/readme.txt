Reference

https://viblo.asia/p/terraform-series-bai-5-terraform-module-create-virtual-private-cloud-on-aws-ORNZqp2MK0n

----------
Commands:
terraform plan -var-file="env.tfvars" -out tfplan.out
terraform apply tfplan.out
terraform destroy --var-file=env.tfvars --auto-approve