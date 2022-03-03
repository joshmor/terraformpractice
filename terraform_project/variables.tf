variable "open_cidr_block_vp4" {
  description = "Value of an open vp4 cidr block"
  type = string
  default = "0.0.0.0/0"
}
variable "private_ip_address" {
  default = "10.0.1.50"
}