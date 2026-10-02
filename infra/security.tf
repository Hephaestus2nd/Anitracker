data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

locals {
  ssh_cidr = var.my_ip_cidr != "" ? var.my_ip_cidr : "${chomp(data.http.my_ip.response_body)}/32"
}

resource "aws_security_group" "api" {
  name        = "${var.project_name}-api-sg"
  description = "API: 8080 from CloudFront only, SSH from admin IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "API traffic from CloudFront edge"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-api-sg" }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "PostgreSQL from the API instance only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from API"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}
