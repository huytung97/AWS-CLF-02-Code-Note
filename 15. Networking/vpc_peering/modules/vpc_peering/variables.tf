variable "source_vpc_id" {
  type = string
}

variable "target_vpc_id" {
  type = string
}

variable "auto_accept" {
  type    = bool
  default = true
}

variable "source_vpc_cidr" {
  type = string
}

variable "target_vpc_cidr" {
  type = string
}