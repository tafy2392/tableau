
variable "secrethub_passphrase" {
  type  = string
  default  = "tanya"
}

provider "google" {
  credentials = file(var.project_path_sa)
  project     = var.project
  version     = "~> 3.15"
  region      = var.region
}

provider "secrethub" {
  credential = file("~/.secrethub/credential")
  credential_passphrase = var.secrethub_passphrase
}

data "secrethub_secret" "tableau_master_password" {
  path = "praekelt/ndoh-tableau/dev/tableau_password"
}



module "tableau_ds_1" {
  source            = "./modules/ndoh-tableau"
  disk_size         = 10
  master_password   = data.secrethub_secret.tableau_master_password.value
  vhost             = "real"
  gce_ssh_user      = "munya"
}
