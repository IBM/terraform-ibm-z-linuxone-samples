provider "ibm-z-linuxone" {
  ibm_z_linuxone_hmc_host      = var.ibm_z_linuxone_host
  ibm_z_linuxone_hmc_username  = var.ibm_z_linuxone_username
  ibm_z_linuxone_hmc_password  = var.ibm_z_linuxone_password
  ibm_z_linuxone_hmc_tls = {
    "insecure_skip_verify" = true
  }
}
import {
  to = YOUR_SYSTEM.YOUR_LPAR
  id = "YOUR_SYSTEM/YOUR_LPAR"
}

