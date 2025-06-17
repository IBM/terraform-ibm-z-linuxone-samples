# GitOps with Terraform Enterprise, Ansible Automation Platform, and Event-Driven Ansible

Automation is the backbone of scalable, reliable, and secure infrastructure. When you work with On-Demand Environments, combining GitOps, Terraform, Ansible Automation Platform, and Event-Driven Ansible creates a powerful, event-driven and declarative infrastructure pipeline.

You can use this sample to implement GitOps, Terraform, Ansible Automation Platform, and Event-Driven Ansible to provision and configure On-Demand z/OS Environments. This powerful combination of tools allows for efficient and automated management of z/OS instances, ensuring that your infrastructure is always up-to-date and configured correctly.

## Key components overview

- GitOps is a methodology that uses Git as the single source of truth for infrastructure and application configurations. It enables version-controlled, auditable, and automated deployments.
- Terraform by HashiCorp is an infrastructure as code (IaC) tool that allows you to define and provision infrastructure by using a declarative configuration language.
- Ansible Automation Platform (AAP) provides enterprise-grade automation capabilities, including workflows, RBAC, and integrations with CI/CD pipelines.
- Event-Driven Ansible (EDA) listens for events (for example, webhook triggers, alerts, or Git changes) and automatically triggers Ansible playbooks in response.

## Prerequisites:
  - IBM Terraform Self-Managed for Z and LinuxONE
  - Ansible Automation Plaform 2.5 (AAP) with Event-Driven Ansible (EDA)
  - Github or Github Enterprise
  - Experience with Terraform, Ansible (including Ansible Automation Plaform and EDA), and Github
  
## Sample Code
- [AAP](AAP/): sample code for code to use with AAP configuration
- [execution_environments](execution_environments/*): sample code to build a suitable execution environment to use with this use case
- [playbook](playbook/): sample playbooks and Terraform variables file
- [rulebook](rulebooks/): sample rulebook to use with EDA
- [terraform](terraform/): sample Terraform configuration files

## Terraform Enterprise Configuration
1. Create an API token (or reuse an exisitng one)
2. Create an organization (or reuse an existing one)
3. Create a workspace for this infrastructure

## AAP Configuration
1. Create an Execution Environment and add it to AAP:
   - Use the sample code in `execution-environments` directory to build an Execution Enviroment suitable to use with Terraform
   - Navigate to Ansible Controller UI    
   - Go to "Automation Execution" --> "Infrastructure" --> "Execution Environments"
   - Click "Add"
   - Specify the EE image you just built

2. Set up Credentials:
   - Go to "Automation Execution" --> "Infrastructure" --> "Credentials"
    
   - Create ***Terraform backend configuration*** credential:
     - Click "Add Credential"
     - Select "*Terraform backend configuration*" as credential type
     - Enter your [Terraform backend block](AAP/Terraform%20backend%20config)
     - Click "Create credential"
  
   - Create ***Source Control*** credential:
     - Click "Add Credential"
     - Select "Source Control" as credential type
     - Enter your Git Personal Access Token
     - Click "Create credential"
      
   - Create a ***Vault*** credential:
     - Click "Add Credential"
     - Select "Vault" as credential type
     - Enter the password you used to encrypte your Terraform variables file
     - Click "Create credential"
      
   - Create a ***Machine*** credential:
     - Click "Add Credential"
     - Select "Machine" as credential type
     - Upload the private SSH that match the public key you are creating your z/OS instance with
     - Click "Create credential"
  
3. Set up Project:
   - Go to "Automation Execution" --> "Projects"
   - Click "Create project"
   - Name your project
   - Select Git as the SCM type
   - Enter your repository URL
   - Enable "Update Revision on Launch"
   - Click "Create project"

4. Create an Inventory
     - Go to "Automation Execution" --> "Inventories"
     - Click “Create inventory" drop-down --> “Create inventory”
     - Enter required information
     - Click "Create inventory"
     - Select the newly created inventory
     - On the Hosts tab, click "Create host"
     - Enter the host name, and use [these host vars](AAP/AAP_host_vars)
     - Click "Create host"
 
5. Set up Templates and Workflow:
   - Go to "Automation Execution" --> "Templates"
   - Click “Create template” --> “Create job template”
   - Configure the job template with:
     - Name: `provision_instance`
     - Inventory
     - Project
     - Execution Environment (use your Terraform EE)
     - Playbook
     - Click “Create job template”
   - Create another additional template named `configure_instance`
   - To create a workflow:
     - Go to "Automation Execution" --> "Templates"
     - Click “Create template” --> “Create workflow job template”
     - Name: `ode_workflow` to match what's specified in the rulebook
     - When done entering values click “Create workflow job template”
     - Add nodes for each job template
     - Configure the workflow paths
     - Save the workflow
  

## EDA Configuration
1. Get Ansible Controller token:
   - Go to "Access Management" --> "Users"
   - Select your user
   - Click the "Tokens" tab
   - Click "Create token"
   - Enter a description
   - Select a Scope --> Read or Write
   - Copy the generated token (to use later)

2. Store the token in EDA:
   - Go to "Automation Decisions (Event-Driven Ansible)" --> "Credentials"
   - Click "Create credential"
   - For Credential type, select "Red Hat Ansible Automation Platform"
   - For Red Hat Ansible Automation Platform, enter the Red Hat Ansible Automation Platform base URL to authenticate with
   - For OAuth Token, Enter the token you generated in step 1
   - Click "Create credential"

3. Create Decision Environment
   - Go to Automation Decisions --> Decision Environments
   - Click "Create decision environment"
   - Enter the required information. For Image, use `quay.io/ansible/ansible-rulebook:latest`
   - Click "Create decision environment"

4. Create a new project
   - Go to Automation Decisions --> Projects
   - Click "Create project"
   - Enter the required information
   - Click "Create project"

5. Set up your rulebook:
   - Go to “Automation Decisions" --> “Rulebook Activations”
   - Click “Create rulebook activation”
   - Enter the required information
   - Confirm that your rulebook is coded with sources, conditions, and actions
      - Configure actions to trigger Ansible Controller templates
   - Save and activate the rulebook activation

6. Configure Git hooks:
   - Copy your EDA URL
   - Go to your Git repository settings menu
   - Navigate to the "Hooks" section
   - Click "Add webhook"
   - Paste the EDA URL as the "Payload URL". Make sure the port number match the port your rulebook is listening on
   - Select application/json for Content type
   - Configure the webhook trigger events (usually push events)
   - Click "Add webhook"
   - Test the webhook to ensure it's working properly

## Test your GitOps flow
1. Modify a playbook or Terraform configuration file
2. Commit and push your changes to Github
3. Observe the followings:
   - Github webhooks send a payload to EDA
   - EDA rulebook processes the webhook and calls the AAP workflow
   - AAP workflow executes the `provision_instance` playbook which in turn calls Terraform to provision an z/OS instance
   - If provision is successful, the workflow calls the `configure_instance` to change the `ibmuser` password