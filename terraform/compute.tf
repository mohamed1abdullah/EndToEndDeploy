# --- Application Load Balancer (Reliability & Scalability) ---
resource "aws_lb" "app_lb" {
  name               = "restaurant-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
}

# --- Target Groups ---
# 1. Frontend Target Group
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 30081        # Must match NodePort in frontend/service.yml
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
  
  health_check {
    path = "/"
    port = 30081
  }
}

# 2. Backend Target Group
resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 30001        # Must match NodePort in backend/service.yml
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path = "/restaurants"
    port = 30001
  }
}

# --- Listener & Routing Rules ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/restaurants*"]
    }
  }
}

# --- EC2 Instance (K3s Node) ---
# Using a single larger instance for Control+Worker to simplify the "EndToEnd"
# For true production scalability, use an Auto Scaling Group here.
resource "aws_instance" "k3s_node" {
  ami                  = "ami-0ecb62995f68bb549" # Ubuntu 20.04/22.04 US-East-1
  instance_type        = "t3.medium"
  subnet_id            = aws_subnet.private_1a.id # Secure in Private Subnet
  iam_instance_profile = aws_iam_instance_profile.app_profile.name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name             = "ssh-key" # Ensure you have this key created or use aws_key_pair resource

  user_data = <<-EOF
              #!/bin/bash
              # 1. Install K3s (Lightweight Kubernetes)
              curl -sfL https://get.k3s.io | sh -
              
              # 2. Install Git & Docker (Optional if using Containerd)
              apt-get update && apt-get install -y git

              # 3. Clone your Repo (Simulated)
              # In a real scenario, use a Personal Access Token or Public Repo
              # git clone https://github.com/tariq126/project-backend.git /app
              
              # 4. Wait for Node to be ready
              sleep 30
              
              # NOTE: You must SSH into this node (via Bastion) 
              # or use a CI/CD pipeline to apply the kubectl manifests.
              EOF

  tags = { Name = "k3s-cluster" }
}

# Register the EC2 instance to BOTH Target Groups
resource "aws_lb_target_group_attachment" "attach_fe" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.k3s_node.id
  port             = 30081
}

resource "aws_lb_target_group_attachment" "attach_be" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.k3s_node.id
  port             = 30001
}