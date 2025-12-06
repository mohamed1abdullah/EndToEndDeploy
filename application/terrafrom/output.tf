output "control_plane_private_ip" {
  description = "private IP address of control plane EC2 "
  value       = aws_instance.control_plane.private_ip
}

output "worker_private_ip" {
  description = "private IP address of worker EC2 "
  value       = aws_instance.worker.private_ip
}