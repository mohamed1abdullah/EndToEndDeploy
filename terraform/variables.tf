# --- Region & Availability Zones ---
variable "region" {
  default = "us-east-1"
}

variable "az_us_east_1a" {
  default = "us-east-1a"
}

variable "az_us_east_1b" {
  default = "us-east-1b"
}

# --- Instance Types ---
variable "instance_type_t2_micro" {
  default = "t2.micro"
}

variable "instance_type_t2_small" {
  default = "t2.small"
}

variable "instance_type_t2_medium" {
  default = "t2.medium"
}

# --- AMI (Ubuntu) ---
variable "ami" {
  default = "ami-0ecb62995f68bb549"
}

# --- CI/CD Secrets (Injected by GitHub Actions) ---
variable "ssh_public_key" {
  description = "Public SSH key passed from GitHub Secrets"
  type        = string
  # No default value here for security; it must be provided by the pipeline
}