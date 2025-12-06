resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.restaurant_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.az_us_east_1a

  tags = {
    Name = "subnet-1a"
  }

}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.restaurant_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.az_us_east_1b

  tags = {
    Name = "subnet-1b"
  }

}
