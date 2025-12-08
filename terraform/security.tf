# --- IAM Role for EC2 ---
# This role allows the EC2 instance to assume an identity that has permissions.
resource "aws_iam_role" "app_role" {
  name = "restaurant_app_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# --- IAM Policy for DynamoDB Access ---
# This specifically grants permission to read/write to DynamoDB.
resource "aws_iam_role_policy" "dynamodb_access" {
  name = "dynamodb_access"
  role = aws_iam_role.app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# --- Instance Profile ---
# This links the IAM Role to the EC2 instance.
resource "aws_iam_instance_profile" "app_profile" {
  name = "restaurant_app_profile"
  role = aws_iam_role.app_role.name
}

# --- Security Groups ---

# 1. Load Balancer Security Group
# Allows the public to access via HTTP (Port 80)
resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Allow public HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Kubernetes Node Security Group
# Allows traffic from the Load Balancer and internal cluster communication
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-node-sg"
  description = "Allow traffic from LB and internal communication"
  vpc_id      = aws_vpc.main.id

  # Allow incoming traffic from the Load Balancer
  ingress {
    from_port       = 30000
    to_port         = 32767
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow SSH access (Open to world for now, restrict IP in production)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Internal Communication (k3s Flannel/VXLAN)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}