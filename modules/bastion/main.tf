resource "aws_instance" "main" {
  ami                         = "ami-0fdfb4d987b63ae72"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = "roboshop_pem"
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.sg_id]
  iam_instance_profile        = var.profile
  root_block_device {
    volume_size = 50
    volume_type = "gp3" # Optional: defaults to standard or gp2 depending on provider version
  }


  tags = {
    Name = "${var.project}-${var.env}-bastion"
  }
}
