resource "aws_internet_gateway" "restaurant_igw" {
  vpc_id = aws_vpc.restaurant_vpc.id
}

