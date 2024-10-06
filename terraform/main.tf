# Master Node
resource "openstack_compute_instance_v2" "poiderosa_k8s_master" {
  name      = "poiderosa-k8s-master"
  flavor_id = "general.large"
  image_id  = "ubuntu-22.04"
  key_pair  = openstack_compute_keypair_v2.default.name
  security_groups = ["projeto-poiderosas-sg"]

  network {
    uuid = "8e9133dd-0907-42f2-866d-c7ad2af7eb9c"
  }

  floating_ip = openstack_networking_floatingip_v2.master_floating_ip.address
}

# Worker Nodes
resource "openstack_compute_instance_v2" "poiderosa_k8s_worker" {
  count     = 2
  name      = "poiderosa-k8s-worker-${count.index}"
  flavor_id = "general.large"
  image_id  = "ubuntu-22.04"
  key_pair  = openstack_compute_keypair_v2.default.name
  security_groups = ["projeto-poiderosas-sg"]

  network {
    uuid = "8e9133dd-0907-42f2-866d-c7ad2af7eb9c"
  }

  floating_ip = openstack_networking_floatingip_v2.worker_floating_ip[count.index].address
}

# Floating IP for Master
resource "openstack_networking_floatingip_v2" "master_floating_ip" {
  pool = "public"
}

# Floating IPs for Worker Nodes
resource "openstack_networking_floatingip_v2" "worker_floating_ip" {
  count = 2
  pool  = "public"
}

# Load Balancer
resource "openstack_lb_loadbalancer_v2" "poiderosa_k8s_lb" {
  name          = "poiderosa-k8s-lb"
  vip_subnet_id = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# HTTP Listener for Load Balancer
resource "openstack_lb_listener_v2" "poiderosa_http_listener" {
  name            = "poiderosa-http-listener"
  protocol        = "HTTP"
  protocol_port   = 25180
  loadbalancer_id = openstack_lb_loadbalancer_v2.poiderosa_k8s_lb.id
}

# Pool for HTTP traffic
resource "openstack_lb_pool_v2" "poiderosa_http_pool" {
  name        = "http_pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_http_listener.id
}

# Associate Control Plane and Workers as Pool Members
resource "openstack_lb_member_v2" "poiderosa_http_members" {
  count          = 3
  pool_id        = openstack_lb_pool_v2.poiderosa_http_pool.id
  address        = element([openstack_compute_instance_v2.poiderosa_k8s_master.access_ip_v4, openstack_compute_instance_v2.poiderosa_k8s_worker[0].access_ip_v4, openstack_compute_instance_v2.poiderosa_k8s_worker[1].access_ip_v4], count.index)
  protocol_port  = 80
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Security Group Rule for SSH (adjusted ports)
resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22119
  port_range_max    = 22121
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.default.id
}

# SSH Listener for Master Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_master" {
  name            = "poiderosa-master-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22119
  loadbalancer_id = openstack_lb_loadbalancer_v2.poiderosa_k8s_lb.id
}

# SSH Listener for Worker 1 Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_worker_1" {
  name            = "poiderosa-worker-1-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22120
  loadbalancer_id = openstack_lb_loadbalancer_v2.poiderosa_k8s_lb.id
}

# SSH Listener for Worker 2 Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_worker_2" {
  name            = "poiderosa-worker-2-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22121
  loadbalancer_id = openstack_lb_loadbalancer_v2.poiderosa_k8s_lb.id
}

# SSH Pool for Master Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_master" {
  name        = "ssh_pool_master"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_master.id
}

# SSH Pool for Worker 1 Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_worker_1" {
  name        = "ssh_pool_worker_1"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_worker_1.id
}

# SSH Pool for Worker 2 Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_worker_2" {
  name        = "ssh_pool_worker_2"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_worker_2.id
}

# Associate Master Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_master" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_master.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_master.access_ip_v4
  protocol_port  = 22119
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Associate Worker 1 Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_worker_1" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_worker_1.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_worker[0].access_ip_v4
  protocol_port  = 22120
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Associate Worker 2 Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_worker_2" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_worker_2.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_worker[1].access_ip_v4
  protocol_port  = 22121
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}
