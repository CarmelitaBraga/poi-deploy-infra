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

# Data source to reference existing load balancer
data "openstack_lb_loadbalancer_v2" "poi_atividades" {
  name = "poi-atividades"
}

# TCP Listener for Load Balancer
resource "openstack_lb_listener_v2" "poiderosa_tcp_listener" {
  name            = "poiderosa-tcp-listener"
  protocol        = "TCP"
  protocol_port   = 25180
  loadbalancer_id = data.openstack_lb_loadbalancer_v2.poi_atividades.id
}

# Pool for TCP traffic
resource "openstack_lb_pool_v2" "poiderosa_tcp_pool" {
  name        = "poiderosas-projeto-tcp-pool"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_tcp_listener.id
}

# Associate Workers as Pool Members
resource "openstack_lb_member_v2" "poiderosa_tcp_members" {
  count          = 2
  pool_id        = openstack_lb_pool_v2.poiderosa_tcp_pool.id
  address        = element([openstack_compute_instance_v2.poiderosa_k8s_worker[0].access_ip_v4, openstack_compute_instance_v2.poiderosa_k8s_worker[1].access_ip_v4], count.index)
  protocol_port  = 80
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Security Group Rule for SSH
resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "TCP"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.default.id
}

# SSH Listener for Master Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_master" {
  name            = "poiderosa-master-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22119
  loadbalancer_id = data.openstack_lb_loadbalancer_v2.poi_atividades.id
}

# SSH Listener for Worker 1 Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_worker_1" {
  name            = "poiderosa-worker-1-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22120
  loadbalancer_id = data.openstack_lb_loadbalancer_v2.poi_atividades.id
}

# SSH Listener for Worker 2 Node
resource "openstack_lb_listener_v2" "poiderosa_ssh_listener_worker_2" {
  name            = "poiderosa-worker-2-ssh-listener"
  protocol        = "TCP"
  protocol_port   = 22121
  loadbalancer_id = data.openstack_lb_loadbalancer_v2.poi_atividades.id
}

# SSH Pool for Master Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_master" {
  name        = "poiderosa-ssh-pool-master"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_master.id
}

# SSH Pool for Worker 1 Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_worker_1" {
  name        = "poiderosa-ssh-pool-worker-1"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_worker_1.id
}

# SSH Pool for Worker 2 Node
resource "openstack_lb_pool_v2" "poiderosa_ssh_pool_worker_2" {
  name        = "poiderosa-ssh-pool-worker-2"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.poiderosa_ssh_listener_worker_2.id
}

# Associate Master Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_master" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_master.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_master.access_ip_v4
  protocol_port  = 22
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Associate Worker 1 Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_worker_1" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_worker_1.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_worker[0].access_ip_v4
  protocol_port  = 22
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Associate Worker 2 Node as Pool Member
resource "openstack_lb_member_v2" "poiderosa_ssh_member_worker_2" {
  pool_id        = openstack_lb_pool_v2.poiderosa_ssh_pool_worker_2.id
  address        = openstack_compute_instance_v2.poiderosa_k8s_worker[1].access_ip_v4
  protocol_port  = 22
  subnet_id      = "17de9c72-e5dc-4da0-ae0a-013f7e42400e"
}

# Allow Kubernetes API access (Port 6443)
resource "openstack_networking_secgroup_rule_v2" "allow_k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.default.id
}

# Allow HTTP traffic (Port 80)
resource "openstack_networking_secgroup_rule_v2" "allow_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.default.id
}