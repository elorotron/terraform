resource "aws_security_group" "backend_sg" {
  name        = "${var.env}-${var.project_name}-backend-sg"
  description = "${var.env}-${var.project_name}-backend-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.backend_ports_open
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-backend-sg"
    },
    var.tags
  )
}

resource "aws_security_group" "frontend_sg" {
  name        = "${var.env}-${var.project_name}-frontend-sg"
  description = "${var.env}-${var.project_name}-frontend-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.frontend_ports_open
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-frontend-sg"
    },
    var.tags
  )
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-${var.project_name}-rds-sg"
  description = "${var.env}-${var.project_name}-rds-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.rds_ports_open
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-rds-sg"
    },
    var.tags
  )
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.env}-${var.project_name}-redis-sg"
  description = "${var.env}-${var.project_name}-redis-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.redis_ports_open
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #any protocol
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-redis-sg"
    },
    var.tags
  )
}