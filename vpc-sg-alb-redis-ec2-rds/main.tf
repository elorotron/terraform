provider "aws" {
  region = "us-west-2"
}

locals {
  #=============main
  env = "dev"
  project_name = "test-project"
  tags = {
    env = "dev"
    Terraform = "true"
    Project = "Other"
  }
  #============VPC=====================
  vpc_name = "${var.env}-${var.project_name}-vpc"
  vpc_cidr = "10.1.0.0/16"
  vpc_azs = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets_cidr = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets_cidr  = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
  database_subnets_cidr = ["10.1.7.0/24", "10.1.8.0/24", "10.1.9.0/24"]
  

  #============SG=====================
  backend_ports = [80, 22]
  frontend_ports = [80, 22]
  rds_ports = [5432]
  redis_ports = [6379]

  #============ALB=====================
  certificate_arn = "arn:aws:acm:us-west-2:2222222222222:certificate/xxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxxx"
  backend_head = ["backend.susel.pics"]
  frontend_head = ["frontend.susel.pics"]

  #============REDIS=====================
  redis_instance_type = "cache.t2.micro"
  redis_engine_version             = "7.1"
  redis_family                     = "redis7"

  #============EC2=====================
  ec2_instance_type = "t2.micro"
  ec2_count_backend = 1
  ec2_count_frontend = 1
  ec2_key_pair_name = "dev_test"

  #============RDS=====================
  rds_instance_class       = "db.t3.small"
  rds_engine = "postgres"
  rds_engine_version       = "16.1"
  rds_major_engine_version = "16"
  rds_family               = "postgres16" 
  rds_allocated_storage     = 30
  rds_max_allocated_storage = 100
  rds_db_name = "testprojectdb"
  rds_username = "postgres"
  rds_port     = 5432
  rds_public_access = true
  region  = "us-west-2"

}

#====================VPC========================
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs             = local.vpc_azs
  private_subnets = local.private_subnets_cidr
  public_subnets  = local.public_subnets_cidr
  database_subnets = local.database_subnets_cidr
  #public access to rds===============
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
  #=================================
  enable_nat_gateway = true
  single_nat_gateway = true #Create only one NAT GW for all subnets if true, otherwise 1 NAT per 1 subnet
  one_nat_gateway_per_az = false

  enable_vpn_gateway = false

  tags = local.tags
}

#====================SG========================

module "sg" {
  source = "../modules/sg"
  backend_ports_open = local.backend_ports
  frontend_ports_open = local.frontend_ports
  rds_ports_open = local.rds_ports
  redis_ports_open = local.redis_ports
  tags = local.tags
  env = local.env
  project_name = local.project_name
  vpc_id = module.vpc.vpc_id
}


#======================ALB=====================

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  enable_deletion_protection = false
  name    = "${var.env}-${var.project_name}-ALB"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  #Listeners
  listeners = {

    http-redirect-to-https = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = local.certificate_arn

      forward = { #Default forward targert group
        target_group_key = "backend-instance"
      }

      rules = {
        backend-forward = {
          priority = 2
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "backend-instance"
                weight           = 1
              }
            ]
            stickiness = {
              enabled  = false
              #duration = 3600
            }
          }]

          conditions = [{
            host_header = {
              host_header_name = "backend"
              values           = local.backend_head
            }
          }]
        }

        frontend-forward = {
          priority = 3
          actions = [{
            type = "weighted-forward"
            target_groups = [
              {
                target_group_key = "frontend-instance"
                weight           = 1
              }
            ]
            stickiness = {
              enabled  = false
              #duration = 3600
            }
          }]

          conditions = [{
            host_header = {
              host_header_name = "frontend"
              values           = local.frontend_head
            }
          }]
        }

      }
    }
  }



  target_groups = {
    backend-instance = {
      name = "${var.env}-${var.project_name}-backend-tg"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = true
      target_id = module.ec2.backend_id[0]
    }
    frontend-instance = {
      name = "${var.env}-${var.project_name}-frontend-tg"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = true
      target_id = module.ec2.frontend_id[0]
    }
  }

  tags = local.tags
}

#====================REDIS========================

module "redis" {
  source = "cloudposse/elasticache-redis/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version = "x.x.x"
  name       = "${var.env}-${var.project_name}-redis"
  availability_zones         = module.vpc.azs
  #zone_id                    = var.zone_id
  vpc_id                     = module.vpc.vpc_id
  #allowed_security_group_ids = [module.sg.redis_sg_id]
  create_security_group = false
  associated_security_group_ids = [module.sg.redis_sg_id]
  #subnets                    = module.vpc.private_subnets
  subnets                    = module.vpc.public_subnets
  cluster_size               = 1
  instance_type              = local.redis_instance_type
  apply_immediately          = true
  automatic_failover_enabled = false
  engine_version             = local.redis_engine_version
  family                     = local.redis_family
  at_rest_encryption_enabled = false
  transit_encryption_enabled = false

  tags = local.tags
  
  parameter = [
    {
      name  = "notify-keyspace-events"
      value = "lK"
    }
  ]
}

#====================EC2========================

module "ec2" {
  source = "../modules/ec2"
  public_subnet_ids = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets
  instance_type = local.ec2_instance_type
  backend_sg_id = module.sg.backend_sg_id
  frontend_sg_id = module.sg.frontend_sg_id
  count_backend = local.ec2_count_backend
  count_frontend = local.ec2_count_frontend
  key_pair_name = local.ec2_key_pair_name
  env = local.env
  project_name = local.project_name
  tags = local.tags
}

#====================RDS========================

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.env}-${var.project_name}-rds"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = local.rds_engine
  engine_version       = local.rds_engine_version
  family               = local.rds_family # DB parameter group
  major_engine_version = local.rds_major_engine_version        # DB option group
  instance_class       = local.rds_instance_class

  allocated_storage     = local.rds_allocated_storage
  max_allocated_storage = local.rds_max_allocated_storage

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = local.rds_db_name
  username = local.rds_username
  port     = local.rds_port

  publicly_accessible = local.rds_public_access
  # setting manage_master_user_password_rotation to false after it
  # has been set to true previously disables automatic rotation
  manage_master_user_password_rotation              = true
  master_user_password_rotate_immediately           = false
  master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.sg.rds_sg_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1 # The days to retain backups for
  skip_final_snapshot     = true # Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted
  deletion_protection     = false # The database can't be deleted when this value is set to true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.env}-RDS-${var.project_name}-monitoring_role"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "${var.env}-RDS-${var.project_name}-monitoring_role"

  parameters = [
    {
      name  = "autovacuum"
      value = 1 #true, see https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Autovacuum.html
    },
    {
      name  = "client_encoding"
      value = "utf8" # Sets the client's character set encoding, https://postgresqlco.nf/doc/en/param/client_encoding/
    }
  ]
  tags = merge(
    {
      "Name" = "${var.env}-${var.project_name}-postgresql"
    },
    local.tags
  )

  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
}
