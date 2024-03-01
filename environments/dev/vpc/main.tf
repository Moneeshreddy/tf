module "vpc" {
  source = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr

  vpc_tags = {
    Name             = "${var.vpc_name}"
    TerraformManaged = true
  }

  igw_tags = {
    Name             = "${var.vpc_name}"
    TerraformManaged = true
  }
}
