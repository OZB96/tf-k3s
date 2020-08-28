output "control_plane" {
  value = aws_instance.controlplane[0].public_ip
}
