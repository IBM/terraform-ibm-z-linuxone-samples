provider "ibm-z-linuxone" {
  ibm_z_linuxone_hmc_tls = {
    "insecure_skip_verify" = true
  }
}
provider "aap" {
    insecure_skip_verify = true
}
import {
  to = ibm-z-linuxone_logical-partition.YOUR_SYSTEM-YOUR_LPAR
  id = "YOUR_SYSTEM/YOUR_LPAR"
}


