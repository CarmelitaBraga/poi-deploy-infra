Ansible configuration files for installing Docker, Kubernetes and deploying application:
---
First things first, if you still don't have ansible installed in your machine, run the following commands:
```
sudo apt install pipx
```
and then:
```
pipx install --include-deps ansible
```
---
To install Docker and Kubernetes, make sure you are in the poi-deploy-infra/ansible directory and run:
```
ansible-playbook k8-playbook.yml -i hosts 
```
---
To configure the Kubernetes cluster, make sure you are in the poi-deploy-infra/ansible directory and run:
```
ansible-playbook k8s-cluster.yml -i hosts
```