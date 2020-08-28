output "control_plan" {
  value = aws_instance.control.plan.public_ip
}
