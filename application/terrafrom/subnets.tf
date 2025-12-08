# --- Public Subnets (For NAT Gateway & Nginx Proxy) ---
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.restaurant_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.az_us_east_1a
  map_public_ip_on_launch = true  # Fixed typo here

  tags = { Name = "public-subnet-1a" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.restaurant_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.az_us_east_1b
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet-1b" }
}

# --- Private Subnets (For K8s Nodes & DB) ---
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.restaurant_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.az_us_east_1a

  tags = { Name = "private-subnet-1a" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.restaurant_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.az_us_east_1b

  tags = { Name = "private-subnet-1b" }
}