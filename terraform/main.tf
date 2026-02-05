# Root Terraform Configuration
# This is the main entry point that orchestrates all modules

# Tier 1: Networking Layer
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# Tier 1.5: Security Layer
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}

# Tier 3: Data Layer (Database & Cache)
module "data" {
  source = "./modules/data"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  db_name            = var.db_name
  db_username        = var.db_username

  # Security groups
  rds_security_group_id   = module.security.rds_security_group_id
  redis_security_group_id = module.security.redis_security_group_id
}

# Tier 2: Compute Layer (ECS)
module "compute" {
  source = "./modules/compute"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  services           = var.services
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  # Security
  ecs_security_group_id = module.security.ecs_security_group_id

  # Data layer endpoints
  rds_endpoint   = module.data.rds_endpoint
  redis_endpoint = module.data.redis_endpoint
  db_secret_arn  = module.data.db_secret_arn
  jwt_secret_arn = module.data.jwt_secret_arn

  # Load balancer
  target_group_arns = module.loadbalancer.target_group_arns
}

# Tier 1: Presentation Layer (Load Balancer)
module "loadbalancer" {
  source = "./modules/loadbalancer"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  services          = var.services

  # Security
  alb_security_group_id = module.security.alb_security_group_id
}
