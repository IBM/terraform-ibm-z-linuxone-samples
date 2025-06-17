terraform { 
  backend "remote" { 
    hostname = "your.terraform.server.com" 
    organization = "your-terraform-org" 
    token = "your-terraform-server-api-token"
    workspaces {name = "some-workspace"} 
  } 
}