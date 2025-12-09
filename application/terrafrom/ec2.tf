# --- SSH Key ---
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "restaurant-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/ssh-key.pem"
  file_permission = "0400"
}

# --- 1. The Gateway / Software Load Balancer (Public) ---
resource "aws_instance" "gateway_proxy" {
  ami           = var.ami
  instance_type = "t2.small"
  subnet_id     = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]
  key_name      = aws_key_pair.ssh_key_pair.key_name

  # --- AUTOMATION SCRIPT ---
  user_data = <<-EOF
              #!/bin/bash
              
              # 1. Install Nginx and Docker
              apt-get update
              apt-get install -y nginx ca-certificates curl gnupg
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
              chmod a+r /etc/apt/keyrings/docker.asc
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
              
              # 2. Configure Gateway Nginx -> Points ONLY to Frontend Workers
              cat <<EOT > /etc/nginx/sites-available/default
              upstream k8s_frontend {
                  server ${aws_instance.worker_1.private_ip}:30081;
                  server ${aws_instance.worker_2.private_ip}:30081;
              }

              server {
                  listen 80;
                  
                  # Send EVERYTHING to the Frontend Pods
                  # The Nginx inside the Pod will split traffic between HTML and Backend API
                  location / {
                      proxy_pass http://k8s_frontend;
                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                  }
              }
              EOT
              systemctl restart nginx

              # 3. Setup Monitoring
              mkdir -p /home/ubuntu/monitoring/prometheus
              cd /home/ubuntu/monitoring

              # === NEW PROMETHEUS CONFIGURATION ===
              cat <<EOT > prometheus/prometheus.yml
              global:
                scrape_interval: 5s
              scrape_configs:
                - job_name: "prometheus"
                  static_configs:
                    - targets: ["prometheus:9090"]

                - job_name: "all_nodes"
                  static_configs:
                    - targets: [
                        # Gateway Node Exporter (runs via docker-compose on this node)
                        "node-exporter:9100", 
                        # K8s Nodes (Master and Workers - will deploy Node Exporter via deploy.tf)
                        "${aws_instance.control_plane.private_ip}:9100", 
                        "${aws_instance.worker_1.private_ip}:9100",      
                        "${aws_instance.worker_2.private_ip}:9100"       
                      ]
              EOT

              cat <<EOT > docker-compose.yml
              version: '3.8'
              services:
                prometheus:
                  image: prom/prometheus:latest
                  container_name: prometheus
                  volumes:
                    - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
                    - prometheus_data:/prometheus
                  ports:
                    - "9090:9090"
                  command:
                    - "--config.file=/etc/prometheus/prometheus.yml"
                  restart: unless-stopped
                grafana:
                  image: grafana/grafana:latest
                  container_name: grafana
                  ports:
                    - "3000:3000"
                  environment:
                    - GF_SECURITY_ADMIN_PASSWORD=admin
                  volumes:
                    - grafana_data:/var/lib/grafana
                  depends_on:
                    - prometheus
                  restart: unless-stopped
                node-exporter:
                  image: prom/node-exporter:latest
                  container_name: node-exporter
                  ports:
                    - "9100:9100"
                  restart: unless-stopped
              volumes:
                prometheus_data:
                grafana_data:
              EOT

              docker compose up -d
              EOF

  tags = { Name = "gateway-proxy-lb" }
}

# --- 2. K8s Control Plane ---
resource "aws_instance" "control_plane" {
  ami           = var.ami
  instance_type = "t2.small"
  subnet_id     = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name      = aws_key_pair.ssh_key_pair.key_name

  tags = { Name = "k8s-control-plane" }
}

# --- 3. K8s Worker 1 ---
resource "aws_instance" "worker_1" {
  ami           = var.ami
  instance_type = "t2.small"
  subnet_id     = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name      = aws_key_pair.ssh_key_pair.key_name

  tags = { Name = "k8s-worker-1" }
}

# --- 4. K8s Worker 2 ---
resource "aws_instance" "worker_2" {
  ami           = var.ami
  instance_type = "t2.small"
  subnet_id     = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name      = aws_key_pair.ssh_key_pair.key_name

  tags = { Name = "k8s-worker-2" }
}