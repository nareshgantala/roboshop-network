resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-${var.env}-ec2-sg"
  description = ""
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}-${var.env}-ec2-sg"
  }
}
