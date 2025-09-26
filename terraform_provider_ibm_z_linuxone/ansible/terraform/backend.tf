terraform { 
  backend "remote" { 
    hostname = "YOUR_TFE_HOSTNAME" 
    organization = "YOUR_ORG" 
    workspaces {name = "YOUR_WORKSPACE_NAME"} 
  } 
}