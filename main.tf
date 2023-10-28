provider "aws" {
  region = var.region
  default_tags {
    tags = var.tag
  }
}

module "aws_vpc_create" {
  source      = "./modules/aws_vpc_create"
  my_name     = var.my_name
  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr
}

module "deploy_instances" {
  source               = "./modules/deploy_instances"
  vpc_id               = module.aws_vpc_create.vpc_id
  subnet_id            = module.aws_vpc_create.subnet_id
  nm_worker            = var.numbers_instans_workers_deploy
  my_name              = var.my_name
  port                 = var.port
  instance_type_master = var.instance_type_master_deploy
  instance_type_worker = var.instance_type_worker_deploy
  path_for_ansible     = var.path_for_ansible
}

locals {
  user_name = var.user[substr(module.deploy_instances.user_from_ami, 0, 4)] //Can do it as below
  //user_name = lookup(var.user, substr(module.deploy_instances.user_from_ami, 0, 4))  
}

module "create_files" {
  source           = "./modules/create_files"
  path_for_ansible = var.path_for_ansible
  master_ip        = module.deploy_instances.master_ip
  workers_ip       = module.deploy_instances.workers_ip.*
  key_name         = module.deploy_instances.key_name
  user             = local.user_name
}

resource "null_resource" "instance_deploy" {
  triggers = {
    timestamp = timestamp() //for ansible-playbook to to run always
  }

  provisioner "remote-exec" {
    inline = ["hostname"]
    connection {
      host        = module.deploy_instances.master_ip //so that the master is created
      type        = "ssh"
      user        = local.user_name
      private_key = file(module.deploy_instances.path_key_file)
    }
  }

  provisioner "remote-exec" {
    inline = ["hostname"]
    connection {
      host        = element(module.deploy_instances.workers_ip, length(module.deploy_instances.workers_ip) - 1) //so that the last worker is created
      type        = "ssh"
      user        = local.user_name
      private_key = file(module.deploy_instances.path_key_file)
    }
  }

  provisioner "local-exec" {
    command = "cd ansible/ && ansible-playbook -e 'region_from_terraform'=${var.region} -e 'nlb_dns_name_from_terraform'=${module.deploy_instances.nlb_dns_name} -e 'domain_from_terraform'=${var.domain} -e 'aws_user_id_from_terraform'=${var.aws_user_id} main.yml"
  } 
}