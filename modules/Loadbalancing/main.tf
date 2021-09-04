# --- loadbalancing/main.tf ---

resource "aws_lb" "mtc_lb" {
  name            = "mtc-loadbalancer"
  subnets         = var.public_subnets
  security_groups = [aws_security_group.matt_lb_sg.id]
  idle_timeout    = 400
}

resource "aws_lb_target_group" "mtc_tg_1" {
  name     = "mtc-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port1
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
  }
}

resource "aws_lb_target_group" "mtc_tg_2" {
  name     = "mtc-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port2
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [name]
  }
  health_check {
    healthy_threshold   = var.elb_healthy_threshold
    unhealthy_threshold = var.elb_unhealthy_threshold
    timeout             = var.elb_timeout
    interval            = var.elb_interval
  }
}

resource "aws_lb_listener" "front_end-https" {
  load_balancer_arn = aws_lb.mtc_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn_elb

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mtc_tg_1.arn
  }
}

resource "aws_lb_listener" "front_end-http" {
  load_balancer_arn = aws_lb.mtc_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener_rule" "listener_rule1" {
  listener_arn = aws_lb_listener.front_end-https.arn
  priority     = "1"
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mtc_tg_1.id
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_alb_listener_rule" "listener_rule2" {
  listener_arn = aws_lb_listener.front_end-https.arn
  priority     = "2"
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mtc_tg_2.id
  }
  condition {
    path_pattern {
      values = ["/app","/app/todos"]
    }
  }
}

resource "aws_security_group" "matt_lb_sg" {
  name   = "lb-sec-group-for-matt"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "lb-secgroup"
  }
}