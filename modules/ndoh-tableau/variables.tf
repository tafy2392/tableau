variable "vhost" { 
  type = string 
}

variable "project" { 
  type    = string
  default = "tablaeu"
}

variable state_storage{
  type    = string
  default = "state-storage02"
}

variable gce_ssh_user {
  type    = string
}

variable gce_ssh_pub_key_file{
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "instance_name" { 
  type    = string
  default = "ndoh-tableau"
}

variable "instance_type" { 
  type    = string
  default = "f1-micro"
}

variable "zone" {
  type    = string
  default ="us-central1-a"    
}

variable "disk_size" {
  type    = number
  default = 10    
}

variable "tableau_firewall" {
  type    = string
  default ="tableau-firewall"    
}

variable "compute_network" {
  type    = string
  default ="table-network"    
}

variable "region" { 
  type    = string
  default = "us-central1"
}

variable "master_password" {
  type = string
}

variable "license_key" { 
  type    = string
  default = ""
}

variable "master_user" {
  type    = string
  default = "tabadmin"
}
