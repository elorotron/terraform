data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "backend" {
  count                  = var.count_backend
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.backend_sg_id]
  subnet_id              = var.public_subnet_ids[count.index]
  key_name               = var.key_pair_name
  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-backend-${count.index + 1}"
    },
    var.tags
  )
}

resource "aws_instance" "frontend" {
  count                  = var.count_frontend
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.frontend_sg_id]
  subnet_id              = var.public_subnet_ids[count.index]
  key_name               = var.key_pair_name
  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-frontend-${count.index + 1}"
    },
    var.tags
  )
}