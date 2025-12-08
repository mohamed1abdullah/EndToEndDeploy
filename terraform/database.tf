resource "aws_dynamodb_table" "restaurants" {
  name           = "Restaurants" # Matches your code exactly
  billing_mode   = "PAY_PER_REQUEST" # Cost-effective Scalability
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "RestaurantTable"
    Environment = "Production"
  }
}