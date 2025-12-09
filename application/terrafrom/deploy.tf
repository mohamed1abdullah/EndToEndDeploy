# --- 0. Generate a Secure Token for the Cluster ---
resource "random_password" "k3s_token" {
  length  = 32
  special = false
}

# --- 1. Setup Master Node ---
resource "null_resource" "setup_master" {
  # Runs on every push to update the app images
  triggers = {
    always_run = "${timestamp()}"
  }

  connection {
    type                = "ssh"
    user                = "ubuntu"
    private_key         = tls_private_key.ssh_key.private_key_pem
    host                = aws_instance.control_plane.private_ip
    bastion_host        = aws_instance.gateway_proxy.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = tls_private_key.ssh_key.private_key_pem
  }

  # Upload K8s Files
  provisioner "file" {
    source      = "${path.module}/../k8s"
    destination = "/home/ubuntu/k8s"
  }

  # Create Secrets
  provisioner "file" {
    destination = "/home/ubuntu/k8s/backend/secrets.yml"
    content     = <<-EOF
      apiVersion: v1
      kind: Secret
      metadata:
        name: env-be
      stringData:
        AWS_REGION: "${var.region}"
        AWS_ACCESS_KEY_ID: "${var.aws_access_key}"
        AWS_SECRET_ACCESS_KEY: "${var.aws_secret_key}"
    EOF
  }

  # Install K3s (Master Mode), Monitoring & Deploy App
  provisioner "remote-exec" {
    inline = [
      # --- FIX: Install Docker & Node Exporter (Safe/Idempotent) ---
      # 1. Install Docker if it's missing
      "if ! command -v docker &> /dev/null; then sudo apt-get update && sudo apt-get install -y docker.io; sudo systemctl enable docker && sudo systemctl start docker; fi",

      # 2. Run Node Exporter if it's not already running
      "if ! sudo docker ps --format '{{.Names}}' | grep -q node-exporter; then sudo docker run -d --restart=always --name=node-exporter -p 9100:9100 -v '/:/host:ro,rslave' quay.io/prometheus/node-exporter:latest --path.rootfs=/host; fi",

      # Install Master with the Pre-Shared Token
      "curl -sfL https://get.k3s.io | K3S_TOKEN='${random_password.k3s_token.result}' sh -",
      "sleep 10",

      # Deploy Resources
      "sudo k3s kubectl apply -R -f /home/ubuntu/k8s/",
      
      # Restart Pods to pull new images
      "sudo k3s kubectl rollout restart daemonset/frontend",
      "sudo k3s kubectl rollout restart daemonset/backend",

      # Wait for rollout
      "sudo k3s kubectl rollout status daemonset/frontend --timeout=180s",
      "sudo k3s kubectl rollout status daemonset/backend --timeout=180s",
      
      # Frontend Config Fix
      "sleep 10",
      "PODS=$(sudo k3s kubectl get pods -l app=frontend --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')",
      "for POD in $PODS; do sudo k3s kubectl exec $POD -- sed -i 's|const API_BASE_URL = \".*\";|const API_BASE_URL = \"\";|g' /usr/share/nginx/html/app.js; done"
    ]
  }
}

# --- 2. Setup Worker 1 ---
resource "null_resource" "setup_worker_1" {
  # Wait for Master to be ready first
  depends_on = [null_resource.setup_master]

  # Only run if the instance ID changes (so we don't rejoin every time)
  triggers = {
    instance_id = aws_instance.worker_1.id
  }

  connection {
    type                = "ssh"
    user                = "ubuntu"
    private_key         = tls_private_key.ssh_key.private_key_pem
    host                = aws_instance.worker_1.private_ip
    bastion_host        = aws_instance.gateway_proxy.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = tls_private_key.ssh_key.private_key_pem
  }

  # Install K3s (Agent Mode) - AUTOMATIC JOIN
  provisioner "remote-exec" {
    inline = [
      # Install Docker & Node Exporter
      "sudo apt-get update && sudo apt-get install -y docker.io",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo docker run -d --restart=always --name=node-exporter -p 9100:9100 -v '/:/host:ro,rslave' quay.io/prometheus/node-exporter:latest --path.rootfs=/host",

      # Join Cluster using the SAME token we gave the Master
      "curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.control_plane.private_ip}:6443 K3S_TOKEN='${random_password.k3s_token.result}' sh -"
    ]
  }
}

# --- 3. Setup Worker 2 ---
resource "null_resource" "setup_worker_2" {
  depends_on = [null_resource.setup_master]

  triggers = {
    instance_id = aws_instance.worker_2.id
  }

  connection {
    type                = "ssh"
    user                = "ubuntu"
    private_key         = tls_private_key.ssh_key.private_key_pem
    host                = aws_instance.worker_2.private_ip
    bastion_host        = aws_instance.gateway_proxy.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = tls_private_key.ssh_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y docker.io",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo docker run -d --restart=always --name=node-exporter -p 9100:9100 -v '/:/host:ro,rslave' quay.io/prometheus/node-exporter:latest --path.rootfs=/host",

      "curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.control_plane.private_ip}:6443 K3S_TOKEN='${random_password.k3s_token.result}' sh -"
    ]
  }
}