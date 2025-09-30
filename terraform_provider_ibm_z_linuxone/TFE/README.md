# Manage z/OS Logical Partitions using GitOps and Terraform Enterprise
# Manage z/OS Logical Partitions using GitOps and Terraform Enterprise

This is a step-by-step guide on using GitOps and Terraform Enterprise to import an existing z/OS LPAR and increase its number of intial CP.

### Prerequisites
1.  **Terraform Enterprise (TFE) Account**: Ensure you have access to TFE with appropriate permissions.
2.  **HMC Account**: Ensure you have credentials with permissions to manage HMC instances.
3.  **Git Repository**: Have a Git repository (e.g., GitHub, GitLab) to store your Terraform configuration.
4.  **Local Tools Installed**:
    *   Git CLI 
    *   Terraform CLI 

### Summary Table of Key Steps
| Step | Action | Tool/Command |
|------|--------|--------------|
| 1 | Prepare your sample repository | `git clone` |
| 2 | Configure your Terraform Enterprise | TFE UI + `backend "remote"` |
| 3 | Pre-Import Preparation | `main.tf`, `providers.tf`, `backend.tf` |
| 4 | Import an existing LPAR and generate a configuration file  | `import {}`, `terraform plan -generate-config-out=` |
| 5 | Update configuration file and push changes to Github | Edit `cp {}` + `git push` |
| 6 | Apply via TFE | TFE run trigger |
---
###  Step 1: Prepare your sample repository
1.  **Clone this repo**:
    ```bash
    cd your-local-directory
    git clone this-repo-url
    ```

2.  **Push this code to your own git repository**:
    ```bash
    git remote add origin <YOUR_REPO_URL>
    git remote -v
    git push -u origin main
    ```

---
###  Step 2: Configure your Terraform Enterprise
1. **Create a TFE Workspace**:
    *   In TFE, create a new workspace linked to your Git repository (VCS connection).
    *   Choose "Version Control Workflow" and select your Git provider.
    *   Map the workspace to your repository URL.
  
2. **Enable Remote Execution Mode**:
    *   Select TFE **Remote Execution** (plans and applies run in TFE infrastructure).
    *   To verify or change this:
        *   Go to your TFE workspace > **Settings** > **General**.
        *   Under **Execution Mode**, ensure "Remote" is selected.
3. **Set Environment Variables in TFE**:
    *   Create the following environment variables for the *ibm_z_linuxone* provider
        *   `IBM_Z_LINUXONE_HOST`
        *   `IBM_Z_LINUXONE_USERNAME` 
        *   `IBM_Z_LINUXONE_PASSWORD` 
        *   `IBM_Z_LINUXONE_TLS_INSECURE_SKIP_VERIFY`
    *   Mark  `IBM_Z_LINUXONE_USERNAME`, `IBM_Z_LINUXONE_PASSWORD`  as sensitive to secure them.
4. **Edit Version Control Setting**:
    * Confirm the repository name is correct
    * Set the *Terraform Working Directory* to match your sample code
    * Enable *Auto-apply*
    * Select *Branch-based* for *VCS Trigger Type* and specify the branch name
    * Set *Automatic Run triggering* to "Always trigger runs"

---
### Step 3: Pre-Import Preparation
1. **Find an existing LPAR using HMC**:  
   Log on to HMC or using HMC APIs to find the existing LPAR you want to update.
   Log on to HMC or using HMC APIs to find the existing LPAR you want to update.

2. ** Review code structure**:  
   The sample code has the following organization for Terraform files:  
   ```
   terraform/
   ├── main.tf          # Provider and resource blocks
   ├── backend.tf       # TFE backend configuration variables
   ├── providers.tf     # Terraform and provider versions
   ``` 
---

### Step 4: Import an existing LPAR and generate configuration file
1. **Use the import block**:  
   Update your [main.tf](terraform/main.tf) to make sure the `import` block matches your environment. 

2. **Configure Backend for TFE**:  
   Update [backend.tf](terraform/backend.tf) to match your TFE configurations.  

3. **Point to your provider**:  
   Update the [providers.tf](terraform/providers.tf) to point to the ibm_z_linuxone provider on your private registry

4. **Generate a configuration file**:  
   Use the following command to generate a configuration file
   ```bash
      terraform plan -generate-config-out=generated_resources.tf
---

### Step 5: Update configuration file and push changes to Github
1. **Update resource configuration file**:  
   Update `generated_resources.tf` to increase the CP `amount=` value to a higher number
   ```hcl
   cp = {
    amount     = your_higher_amount,
    ...
  }
  ```

2. **Verify the update plan**:  
   - Run `terraform plan` 
   - Verify the output that shows the correct change
  
3. **Commit and push changes to Git**:  
   ```bash
      git add .
      git commit -sm "your_commit_message"
      git push
   ```
   This triggers the TFE pipeline automatically.

4. **Optional: Review Apply changes via TFE**:  
   Review the run output in TFE and check the state file for correct changes.
4. **Optional: Review Apply changes via TFE**:  
   Review the run output in TFE and check the state file for correct changes.
---

### Step 6: Verify LPAR CP `amount=` number changed in HMC
### Step 6: Verify LPAR CP `amount=` number changed in HMC
   Log on to HMC to confirm the LPAR now shows the new number of CP.

This sample shows how to combine GitOps for change tracking and TFE for state management. The approach ensures a controlled and auditable process for importing and modifying existing z/OS LPAR resources.
