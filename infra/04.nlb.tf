resource "aws_lb_target_group" "main" {
  name     = "${local.name}-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled  = true
    protocol = "TCP"
  }
}

resource "aws_lb" "main" {
  name                = "${local.name}-lb"
  internal            = false
  load_balancer_type  = "network"
  subnets             = [for subnet in aws_subnet.public : subnet.id]

  tags = {
    Name        = "${local.name}-lb"
    Environment = local.environment
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_target_group_attachment" "instances" {
  count            = length(local.public_subnets)

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = element(aws_instance.main.*.id, count.index)
  port             = 80
}

output "nlb_dns_name" {
  value = aws_lb.main.dns_name
}