# --- 1. Setup Master Node ---
resource "null_resource" "setup_master" {
  # This ensures the script runs EVERY time you push code, 
  # so it updates the app with the new Docker images.
  triggers = {
    always_run = "${timestamp()}"
  }

  # Connection via Gateway (Bastion)
  connection {
    type                = "ssh"
    user                = "ubuntu"
    private_key         = tls_private_key.ssh_key.private_key_pem
    host                = aws_instance.control_plane.private_ip
    bastion_host        = aws_instance.gateway_proxy.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = tls_private_key.ssh_key.private_key_pem
  }

  # 1. Upload the k8s folder
  provisioner "file" {
    source      = "${path.module}/../k8s"
    destination = "/home/ubuntu/k8s"
  }

  # 2. Create the Secrets file directly
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

  # 3. Install K3s, Deploy, and Restart Pods
  provisioner "remote-exec" {
    inline = [
      # Install K3s (Safe to run multiple times, acts as update/check)
      "curl -sfL https://get.k3s.io | sh -",
      "sleep 10",

      # Apply K8s Manifests (Updates Service/Deployment definitions)
      "sudo k3s kubectl apply -R -f /home/ubuntu/k8s/",
      
      # Force Restart to Pull New Docker Images from Hub
      "sudo k3s kubectl rollout restart daemonset/frontend",
      "sudo k3s kubectl rollout restart daemonset/backend",

      # Wait for pods to restart and apply the relative path fix
      "sleep 30", 
      "PODS=$(sudo k3s kubectl get pods -l app=frontend -o jsonpath='{.items[*].metadata.name}')",
      "for POD in $PODS; do sudo k3s kubectl exec $POD -- sed -i 's|const API_BASE_URL = \".*\";|const API_BASE_URL = \"\";|g' /usr/share/nginx/html/app.js; done"
    ]
  }
}