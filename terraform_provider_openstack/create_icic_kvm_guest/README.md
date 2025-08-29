# create_cic_kvm_guest
The terraform files in this directory can be used to create a RHEL KVM guest within IBM Cloud Infrastructure Center using Terraform. This automation mainly relies on the [OpenStack provider](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs). Even though we are creating s390x guests, the Terraform needs to be ran from an x86 machine as to the best of my knowledge, the OpenStack provider is not built for s390x.

# Prerequisites
1. Get an OS image to use. The qcow2 that I used was for RHEL 9.2. I believe these can be downloaded from RedHat, for instance [from here](https://access.redhat.com/downloads/content/73/ver=/rhel---9.2/9.2/s390x/product-software).
2. I am working in a previously created project in Cloud Infrastructure Center, though I should add to the automation to just automatically create the project. If you don't already have a project, create one.
3. Create an `icic.tfvars` file with your instance specific variables and set some user variables in`sample_user-data`. 

# Execution
*From an x86 machine* install the Terraform binary, then use the following as necessary:
- `terraform init` to initialize Terraform
- `terraform plan -var-file=icic.tfvars` to check the 
- `terraform apply -var-file=icic.tfvars` to create the guest
- `terraform destroy -var-file=icic.tfvars` to remove the guest

# Future improvements:
1. Automatically create a new ICIC project for the guest. 
2. Can we create an OCP guest with Terraform in ICIC? I'm assuming yes, it's just a matter of actually writing it
3. Create guest in a z/VM ICIC environment. It should be similar but I think I need to be more careful about the image used since it's IPL device might be different
4. Checking hypervisor type to make sure the guest is being deployed on a KVM hypervisor?
