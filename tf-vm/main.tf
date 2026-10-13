provider "aws" {
  region = var.region
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-13-amd64-*"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "cle-srv-test"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "ssh" {
  name        = "ssh-depuis-srv-test"
  description = "SSH depuis srv-test"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_admin]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_admin]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vm" {
  count                  = var.nombre_vm
  ami                    = data.aws_ami.debian.id
  instance_type          = var.type_instance
  key_name               = aws_key_pair.admin.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = format("%s-%02d", var.prefixe_nom, count.index + 1)
  }
}

resource "local_file" "inventaire" {
  filename = "${path.module}/../ansible-lab/inventaire.ini"
  content = templatefile("${path.module}/inventaire.tpl", {
    vms = [for vm in aws_instance.vm : { nom = vm.tags.Name, ip = vm.private_ip }]
  })
}
