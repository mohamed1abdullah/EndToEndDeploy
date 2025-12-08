# --- Public Route Table ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.restaurant_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.restaurant_igw.id
  }
  tags = { Name = "public-rt" }
}

# Associate BOTH Public Subnets
resource "aws_route_table_association" "public_assoc_1" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_1.id
}
resource "aws_route_table_association" "public_assoc_2" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_2.id
}

# --- Private Route Table ---
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.restaurant_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "private-rt" }
}

# Associate BOTH Private Subnets
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}