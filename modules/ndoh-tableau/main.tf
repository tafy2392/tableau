locals {
  data_device = "/dev/sdb1"
}

resource "google_storage_bucket" "state_storage" {
  name               = var.state_storage
  force_destroy      = false

}

resource "google_compute_address" "static" {
  name          = "ipv4-address"
  address_type  = "EXTERNAL"  
}

resource "google_compute_instance" "tableau" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
    name       = "ndoh-tableau"
  }


  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork       = google_compute_subnetwork.subnetwork.self_link
    access_config {
       nat_ip = google_compute_address.static.address
     }
  }
   metadata_startup_script = data.template_file.init.rendered
}

resource "google_compute_firewall" "tableau" {
  name         = var.tableau_firewall
  network      = google_compute_network.vpc.name

  allow {
    protocol   = "tcp"
    ports      = ["80", "443", "22"]
  }

 source_ranges =["0.0.0.0/0", "10.0.0.0/8"]
}

resource "google_compute_network" "vpc" {
  name                    = var.compute_network
  auto_create_subnetworks = false  
}

resource "google_compute_subnetwork" "subnetwork" {
  name              = "table-subnetwork"
  ip_cidr_range     = "10.10.10.0/24"
  network           = google_compute_network.vpc.name
  region            = var.region
}

resource "google_compute_disk" "tableau" {
  name                      = "tableau-disk"
  zone                      = var.zone
  size                      = var.disk_size
  image                     = data.google_compute_image.my_image.self_link
  labels = {
            name = var.instance_name
  }
  physical_block_size_bytes = 4096
}

resource "google_compute_attached_disk" "tableau" {
  disk     = google_compute_disk.tableau.id
  instance = google_compute_instance.tableau.id
}

data "google_compute_image" "my_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

data "template_file" "init" {
  template = file("${path.module}/init.tpl")
  vars = {
    data_dev     = local.data_device
    tab_password = var.master_password
    tab_user     = var.master_user
    tab_lic_key  = var.license_key
    vhost        = var.vhost
  }
}


