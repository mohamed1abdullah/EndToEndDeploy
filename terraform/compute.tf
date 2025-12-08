# --- Application Load Balancer ---
resource "aws_lb" "app_lb" {
  name               = "restaurant-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_1a.id, aws_subnet.public_1b.id]
}

# --- Target Groups ---
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 30081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"
  
  health_check {
    path = "/"
    port = 30081
    interval = 10
    timeout  = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 30001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path = "/restaurants"
    port = 30001
    interval = 10
    timeout  = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# --- Listeners ---
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

# --- SSH Key Pair ---
resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "deploy-key"
  public_key = var.ssh_public_key
}

# --- Launch Template (The Blueprint) ---
resource "aws_launch_template" "k3s_template" {
  name_prefix   = "k3s-node-"
  image_id      = var.ami
  instance_type = var.instance_type_t2_medium

  # Security & Permissions
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.app_profile.name
  }
  key_name = aws_key_pair.ssh_key_pair.key_name

  # --- AUTOMATED STARTUP SCRIPT ---
  user_data = base64encode(<<-EOF
              #!/bin/bash
              
              # 1. Update and Install Prerequisites
              apt-get update
              apt-get install -y git curl

              # 2. Install K3s (Lightweight Kubernetes)
              curl -sfL https://get.k3s.io | sh -
              
              # 3. Wait for K3s to be ready (Loop until active)
              echo "Waiting for K3s to start..."
              while ! systemctl is-active --quiet k3s; do
                  sleep 5
              done
              echo "K3s is ready!"

              # 4. Clone Your Application Code
              # We clone to /home/ubuntu/app so it persists
              mkdir -p /home/ubuntu/app
              cd /home/ubuntu/app
              git clone https://github.com/mohamed1abdullah/EndToEndDeploy.git .
              
              # 5. Apply Kubernetes Manifests
              # This commands forces the new server to deploy your app immediately
              
              # Apply Backend (Secrets, Deployment, Service)
              sudo k3s kubectl apply -f application/k8s/backend/
              
              # Apply Frontend (Deployment, Service)
              sudo k3s kubectl apply -f application/k8s/frontend/
              
              # 6. Success Flag
              echo "Deployment Complete!" > /var/log/deployment_status.txt
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k3s-cluster-node"
    }
  }
}

# --- Auto Scaling Group (The Manager) ---
resource "aws_autoscaling_group" "k3s_asg" {
  name                = "k3s-asg"
  vpc_zone_identifier = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
  
  # Redundancy Settings
  desired_capacity    = 2  # Keep 2 running always
  min_size            = 2  # Never drop below 2
  max_size            = 3  # Allow burst up to 3

  # Use the template above
  launch_template {
    id      = aws_launch_template.k3s_template.id
    version = "$Latest"
  }

  # Automatically register new instances to the Load Balancer
  target_group_arns = [
    aws_lb_target_group.frontend_tg.arn,
    aws_lb_target_group.backend_tg.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "k3s-auto-scaled"
    propagate_at_launch = true
  }
}