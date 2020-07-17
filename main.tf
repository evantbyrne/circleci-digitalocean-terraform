variable "branch" {
  description = "Branch. Typically matches git branch."
  type = string
}

variable "do_count" {
  default = "1"
  description = "Number of droplets to create. Max of 8."
  type = string
}

variable "do_image" {
  description = "Droplet image ID. May be a snapshot."
  type = string
}

variable "do_region" {
  default = "nyc1"
  description = "Droplet region."
  type = string
}

variable "do_ssh_keys" {
  description = "List of SSH configuration IDs on DigitalOcean."
  type = list
}

variable "do_size" {
  default = "s-1vcpu-1gb"
  description = "Droplet size."
  type = string
}

variable "do_token" {
  description = "DigitalOcean security access token."
  type = string
}

variable "file_ssh_private_key" {
  default = "~/.ssh/id_rsa"
  description = "Path to local SSH private key."
  type = string
}

provider "digitalocean" {
  token = var.do_token
}

# Create nginx webservers.
resource "digitalocean_droplet" "nginx" {
  count = tonumber(var.do_count)
  image  = var.do_image
  name   = "nginx"
  region = var.do_region
  size   = var.do_size
  ssh_keys = var.do_ssh_keys
  tags = [
    "master",
    "master-${count.index+1}"
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = file(var.file_ssh_private_key)
    timeout = "2m"
  }

  lifecycle {
    create_before_destroy = true
  }

  provisioner "remote-exec" {
    inline = [
      "whoami"
    ]
  }
}

resource "digitalocean_loadbalancer" "load_balancer" {
  droplet_ids = digitalocean_droplet.nginx.*.id
  name = "load-balancer-master"
  region = var.do_region

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"
    target_port = 80
    target_protocol = "http"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }
}
