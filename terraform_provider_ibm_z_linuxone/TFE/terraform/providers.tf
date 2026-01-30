terraform {
  required_providers {
    ibm-z-linuxone = {
      source = "YOUR_TERRAFORM_ENTERPRISE_HOSTNAME/YOUR_ORGANIZATION_NAME/ibm-z-linuxone"
      version = "1.1.0"
    }
    aap = {
      source  = "ansible/aap"
    }
  }
}
