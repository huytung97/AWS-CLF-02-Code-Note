variable "main_vpc_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_pair_name" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "server_port" {
  type    = number
  default = 80
}