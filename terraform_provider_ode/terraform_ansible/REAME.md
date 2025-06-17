# Provisioning a z/OS Instance with On-Demand Environments provider and Changing Password with Ansible

Terraform and Ansible are powerful tools that, when combined, enable a seamless workflow for provisioning and configuring infrastructure.

## Terraform: Infrastructure as Code (IaC)
Terraform is used to provision infrastructure. It defines resources like virtual machines, networks, and storage by using declarative configuration files. In this guide:

- Terraform uses the On-Demand Environments provider to provision a z/OS instance.
- It defines the instance’s properties (CPU, RAM, image, SSH keys, and more) in a `main.tf` file.
- It also dynamically creates an Ansible inventory by using the `ansible_host` resource.

## Ansible: Configuration as Code (CaC)
Ansible is used to configure the provisioned infrastructure. It connects to the instance and executes tasks like installing software, changing settings, or managing users. In this guide:

- You use an Ansible playbook (change_ibmuser_password.yml) to change the ibmuser password on the z/OS instance.
- The playbook is triggered automatically after provisioning by using Terraform’s `local-exec` provisioner.

## Playbooks
- [***configure_instance***](playbook/configure_instance.yml): change the `ibmuser` user password

## Terraform configuration files
- [***backend.tf***](terraform/backend.tf): remote backend for state file
- [***main.tf***](terraform/backend.tf): main configuration file
- [***terraform.tfvars***](terraform/terraform.tfvars): variable values to be used 
- [***variables.tf***](terraform/variables.tf): variables definition


## Execution
From the termninal, navigate to the `terraform` directory and run the following commands:
- `terraform init` to initialize Terraform
- `terraform plan` to check for Terroform errors
- `terraform apply` to provision an zos instance
- `terraform destroy` to de-provision the zos instance