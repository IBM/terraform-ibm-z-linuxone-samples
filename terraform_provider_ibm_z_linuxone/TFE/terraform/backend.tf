terraform { 
  backend "remote" { 
    hostname = "YOUR_TERRAFORM_ENTERPRISE_HOSTNAME" 
    organization = "YOUR_ORGANIZATION_NAME" 
    workspaces {name = "YOUR_WORKSPACE_NAME"} 
  } 
}