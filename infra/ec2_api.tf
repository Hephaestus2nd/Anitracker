data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.api_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = var.key_name

  # replace() guards against CRLF line endings from a Windows checkout breaking the bash script.
  user_data = replace(templatefile("${path.module}/templates/api_user_data.sh.tftpl", {
    repository_url   = var.repository_url
    repository_ref   = var.repository_ref
    db_host           = aws_db_instance.main.address
    db_port           = aws_db_instance.main.port
    db_name           = local.db_name
    db_admin_user     = local.db_admin_user
    db_admin_password = random_password.db_admin.result
    db_app_user       = local.db_app_user
    db_app_password   = random_password.db_app.result
  }), "\r\n", "\n")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-api" }
}

