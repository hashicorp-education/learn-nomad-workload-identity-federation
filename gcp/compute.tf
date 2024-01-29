resource "google_compute_instance_template" "nomad" {
  name   = "nomad-instance-template"
  region = var.region

  lifecycle {
    # Avoid errors where terraform tries to destroy/create the template on
    # subsequent runs and fails due to it being in use
    ignore_changes = [network_interface]
  }

  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "projects/debian-cloud/global/images/family/debian-11"
    disk_size_gb = 40
    type         = "PERSISTENT"
  }

  machine_type = "n1-standard-1"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }
    network    = "global/networks/default"
    subnetwork = "regions/${var.region}/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }

  metadata_startup_script = <<EOF
#!/bin/sh
apt update
apt install -y unzip docker.io gpg coreutils jq
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt -y install nomad
EOF

  service_account {
    email  = "default"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/pubsub", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  tags = ["allow-health-check"]
}

resource "google_compute_instance_group_manager" "nomad" {
  name = "nomad-igm"
  zone = var.zone

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.nomad.id
    name              = "primary"
  }

  base_instance_name = "vm"
  target_size        = 1
}

