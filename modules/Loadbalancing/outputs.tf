output "lb_target_group_arn" {
  value = aws_lb_target_group.mtc_tg.arn
}

output "lb_endpoint" {
  value = aws_lb.mtc_lb.dns_name
}

output "sg_group" {
  value = [aws_security_group.matt_lb_sg.id]
}