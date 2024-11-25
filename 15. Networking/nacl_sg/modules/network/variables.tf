variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "vpc_tags" {
  type = map(string)
}

variable "subnet_cidr" {
  type = string
}