# ---------------------------------------------------------------------------
# Security Group — firewall rules for the EC2 instance
# ---------------------------------------------------------------------------
resource "aws_security_group" "judge_sg" {
  name        = "online-judge-sg"
  description = "Allow SSH, backend (3000), frontend (5173)"

  # SSH — so Ansible can connect
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Backend API
  ingress {
    description = "Backend API"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Frontend
  ingress {
    description = "Frontend"
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ALL outbound traffic (so the server can pull Docker images, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "online-judge-sg"
    Project = "devops-online-judge"
  }
}

# ---------------------------------------------------------------------------
# EC2 Instance — the actual server
# ---------------------------------------------------------------------------
resource "aws_instance" "judge_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.judge_sg.id]

  # This script runs ONCE when the instance first boots.
  # It installs Docker and Docker Compose so Ansible can use them immediately.
  user_data = <<-USERDATA
    #!/bin/bash
    set -eux

    # Update packages
    apt-get update -y
    apt-get upgrade -y

    # Install Docker from official repo
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
      > /etc/apt/sources.list.d/docker.list

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Let the 'ubuntu' user run docker without sudo
    usermod -aG docker ubuntu

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Pre-pull code runner images so first submission is fast
    docker pull python:3.10-slim
    docker pull gcc:latest
  USERDATA

  root_block_device {
    volume_size = 20 # GB — enough for Docker images
    volume_type = "gp3"
  }

  tags = {
    Name    = "online-judge-server"
    Project = "devops-online-judge"
  }
}
