module "networking" {
  source   = "./modules/networking"
  vpc_cidr = var.vpc_cidr
  project  = var.project
  env      = var.env
}

module "iam" {
  source  = "./modules/iam"
  project = var.project
  env     = var.env
}
module "security" {
  source  = "./modules/security"
  vpc_id  = module.networking.vpc_id
  project = var.project
  env     = var.env
}


module "bastion" {
  source        = "./modules/bastion"
  subnet_id     = module.networking.public_subnet_id[0]
  sg_id         = module.security.ec2_sg_id
  project       = var.project
  env           = var.env
  profile       = module.iam.profile_id
  instance_type = var.bastion_instance_type
}


module "jenkins" {
  source        = "./modules/jenkins"
  subnet_id     = module.networking.public_subnet_id[0]
  sg_id         = module.security.ec2_sg_id
  project       = var.project
  env           = var.env
  profile       = module.iam.profile_id
  instance_type = var.jenkins_instance_type
}


module "sonarqube" {
  source        = "./modules/sonarQube"
  subnet_id     = module.networking.public_subnet_id[0]
  sg_id         = module.security.ec2_sg_id
  project       = var.project
  env           = var.env
  profile       = module.iam.profile_id
  instance_type = var.sonarqube_instance_type
}


