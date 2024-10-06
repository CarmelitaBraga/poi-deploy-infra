terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.0"
    }
  }
}

provider "openstack" {
  user_name   = var.USER_NAME
  tenant_name = var.TENANT_NAME
  password    = var.USER_PASSWORD
  auth_url    = var.AUTH_URL
  domain_name = var.DOMAIN_NAME
}

resource "openstack_compute_keypair_v2" "poiderosas-kp" {
  name       = "projeto-poiderosas-kp"
  public_key = file("~/.ssh/projeto_poi.pub")
}
