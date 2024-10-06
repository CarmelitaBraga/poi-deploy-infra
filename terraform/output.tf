output "master_ip" {
  value = openstack_compute_instance_v2.poiderosa-k8s_master.access_ip_v4
}

output "worker_ips" {
  value = openstack_compute_instance_v2.poiderosa-k8s_worker[*].access_ip_v4
}
