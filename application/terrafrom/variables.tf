variable "region" {
  default = "us-east-1"
}

variable "az_us_east_1a" {
  default = "us-east-1a"
}

variable "az_us_east_1b" {
  default = "us-east-1b"
}

variable "instance_type_t2_micro" {
  default = "t2.micro"
}

variable "instance_type_t2_small" {
  default = "t2.small"
}

variable "instance_type_t2_medium" {
  default = "t2.medium"
}

variable "ami" {
  # Ubuntu
  default = "ami-0ecb62995f68bb549"
}

variable "fe_eip_allocation_id" {
    default = "eipalloc-02c9f7b1971f90bd6"
}
variable "be_eip_allocation_id" {
    default = "eipalloc-0384517a51d6a6a18"
}