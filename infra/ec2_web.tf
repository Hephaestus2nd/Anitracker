resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.api_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_name

  user_data = replace(templatefile("${path.module}/templates/web_user_data.sh.tftpl", {
    bootstrap_revision = var.bootstrap_revision
    repository_url = var.repository_url
    repository_ref = var.repository_ref
    api_private_ip = aws_instance.api.private_ip
  }), "\r\n", "\n")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-web" }
}
