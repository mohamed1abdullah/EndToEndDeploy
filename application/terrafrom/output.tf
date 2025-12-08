output "gateway_public_ip" {
  description = "Access your application here (Software LB)"
  value       = aws_instance.gateway_proxy.public_ip
}

output "control_plane_private_ip" {
  value = aws_instance.control_plane.private_ip
}

output "worker_1_private_ip" {
  value = aws_instance.worker_1.private_ip
}

output "worker_2_private_ip" {
  value = aws_instance.worker_2.private_ip
}