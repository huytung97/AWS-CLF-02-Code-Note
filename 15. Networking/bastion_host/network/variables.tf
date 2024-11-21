variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

variable "vpc_tags" {
  type = map(string)
}

variable "az" {
  type = list(string)
}

# variable "private_subnets_cidr" {
#     type = list(string)
# }

variable "public_subnet_cidr" {
    type = string
}

# variable "availability_zone" {
#     type = list(string)
# }