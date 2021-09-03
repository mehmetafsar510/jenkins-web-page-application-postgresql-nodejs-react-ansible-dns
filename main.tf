module "iam" {
  source = "./modules/IAM"
}

module "network" {
  source           = "./modules/Network"
  vpc_cidr_block   = var.vpc_cidr
  public_sn_count  = 2
  private_sn_count = 2
  max_subnets      = 6
  public_cidrs     = [for i in range(10, 255, 10) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_cidrs    = [for i in range(11, 255, 10) : cidrsubnet(var.vpc_cidr, 8, i)]
}

module "compute" {
  source              = "./modules/Compute"
  instance_count      = 1
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnet[0]
  master_profile_name = module.iam.master_profile_name
  worker_profile_name = module.iam.worker_profile_name
  key_name            = var.key_name
  lb_target_group_arn = module.loadbalancing.lb_target_group_arn
  tg_port             = 3000
}

module "loadbalancing" {
  source                  = "./modules/Loadbalancing"
  public_subnets          = module.network.public_subnet
  tg_port                 = 3000
  tg_protocol             = "HTTP"
  vpc_id                  = module.network.vpc_id
  elb_healthy_threshold   = 2
  elb_unhealthy_threshold = 2
  elb_timeout             = 3
  elb_interval            = 30
  listener_port           = 443
  listener_protocol       = "HTTPS"
  certificate_arn_elb     = "{{carn}}"
}
