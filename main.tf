module "networking" {
  source   = "../modules/networking"
  vpc_cidr = var.vpc_cidr
  project  = var.project
  env      = var.env
}
