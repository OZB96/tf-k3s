output "control_plane" {
  value = aws_instance.controlplane[0].public_ip
}

output "worker1" {
  value = aws_instance.worker[0].private_ip
}

output "worker2" {
  value = aws_instance.worker[1].private_ip
}
