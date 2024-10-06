provider "openstack" {
  user_name   = getenv("USER_NAME")
  tenant_name = getenv("TENANT_NAME")
  password    = getenv("USER_PASSWORD")
  auth_url    = getenv("AUTH_URL")
  domain_name = getenv("DOMAIN_NAME")
}

resource "openstack_compute_keypair_v2" "default" {
  name       = "projeto-poiderosas-kp"
  public_key = file("~/.ssh/projeto_poi.pub")
}
