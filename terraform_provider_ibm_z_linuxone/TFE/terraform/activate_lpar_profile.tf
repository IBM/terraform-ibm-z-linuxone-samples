
# Get existing job template by name
# This assumes you have a job template named "z-provider-activate-lpar-profile" in your AAP instance
# Adjust the name and organization as necessary
data "aap_job_template" "z-provider-activate-lpar-profile" {
    name              = "z-provider-activate-lpar-profile"
    organization_name = "Default"
}

resource "null_resource" "lpar_changed" {
  triggers = {
    change_fingerprint = jsonencode(ibm-z-linuxone_logical-partition.YOUR_SYSTEM-YOUR_LPAR)
  }
}

resource "aap_job" "activate_lpar_profile" {
    depends_on = [ibm-z-linuxone_logical-partition.YOUR_SYSTEM-YOUR_LPAR]
    job_template_id = data.aap_job_template.z-provider-activate-lpar-profile.id

    extra_vars = jsonencode({
        "cpc_name" = ibm-z-linuxone_logical-partition.YOUR_SYSTEM-YOUR_LPAR.system_name
        "target_lpar" = ibm-z-linuxone_logical-partition.YOUR_SYSTEM-YOUR_LPAR.name
        })

    # only runs when the null_resource detects a change
    triggers = {
        lpar_fingerprint = null_resource.lpar_changed.triggers.change_fingerprint
    }
}