resource "aws_security_group" "ec2_sg" {
  name        = "${var.project}-${var.env}-ec2-sg"
  description = ""
  vpc_id      = var.vpc_id
  ingress {
    description = "Internal SSH for Jenkins Controller to Worker Node"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
  }
  # Internal: Bastion Worker -> SonarQube scan reports
  ingress {
    description = "SonarQube internal access for build scans"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "${var.project}-${var.env}-ec2-sg"
  }
}
