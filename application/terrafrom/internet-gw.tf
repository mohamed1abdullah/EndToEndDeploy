resource "aws_internet_gateway" "restaurant_igw" {
  vpc_id = aws_vpc.restaurant_vpc.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.restaurant_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.restaurant_igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.subnet2.id
}
