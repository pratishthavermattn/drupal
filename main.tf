locals {
  name = "demo-vpc"
}

module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v3.0.0"

  name = local.name
  cidr = "10.99.0.0/18"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.99.0.0/24", "10.99.1.0/24", "10.99.2.0/24"]
  private_subnets = ["10.99.3.0/24", "10.99.4.0/24", "10.99.5.0/24"]

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "security_group_asg" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-security-group.git?ref=v4.0.0"

  name   = "security-group_asg"
  vpc_id = module.vpc.vpc_id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Open internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [

    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "205.254.162.221/32"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = "205.254.162.221/32"
    },
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS"
      cidr_blocks = "205.254.162.221/32"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "ALB Port Open in ASG"
      cidr_blocks = "10.99.0.0/18"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "205.254.162.221/32"
    }
  ]
}

module "security_group_rds" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-security-group.git?ref=v4.0.0"

  name   = "security-group_rds"
  vpc_id = module.vpc.vpc_id
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "all"
      description = "Open internet"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "All TCP"
      cidr_blocks = "205.254.162.221/32"
    }
  ]

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "Added ASG SG"
      source_security_group_id = module.security_group_asg.security_group_id
    }
  ]

  number_of_computed_ingress_with_source_security_group_id = 1
}

module "test_alb" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-alb.git?ref=v6.0.0"

  name = "test-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.security_group_asg.security_group_id]

  target_groups = [
    {
      name             = "test-target-group"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      health_check = {
        enabled             = true
        interval            = 110
        path                = "/drupal"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 100
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      action_type        = "forward"
    }
  ]

  tags = {
    Project = "terraform_drupal"
    Name    = "terraform_asg_cluster"
    BU      = "demo-testing"
    Owner   = "pratishtha.verma@tothenew.com"
    Purpose = "gtihub project"
  }
}

module "drupal" {
  source = "../terraform-aws-drupal/"
  #demo          = module.vpc.public_sn_asg
  
  vpc_drupal           = module.vpc.vpc_id
  sec_group_drupal_rds = module.security_group_rds.security_group_id
  subnet_drupal_rds    = module.vpc.public_subnets

  subnet_drupal_asg    = module.vpc.public_subnets
  sec_group_drupal_asg = module.security_group_asg.security_group_id

  vpc_drupal_alb       = module.vpc.vpc_id
  sec_group_drupal_alb = module.security_group_asg.security_group_id
  subnet_drupal_alb    = module.vpc.public_subnets

  subnet_drupal_efs    = module.vpc.public_subnets
  sec_group_drupal_efs = module.security_group_asg.security_group_id
  vpc_drupal_efs       = module.vpc.vpc_id  

  #target_group_drupal  = var.create ? var.xyz : module.test_alb.target_group_arns 
  
  target_group_drupal  = module.test_alb.target_group_arns
}
