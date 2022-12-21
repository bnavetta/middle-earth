terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }

    cloudinit = {
      source = "hashicorp/cloudinit"
    }

    tailscale = {
      source = "tailscale/tailscale"
    }

    namecheap = {
      source = "namecheap/namecheap"
    }

    github = {
      source = "integrations/github"
    }
  }
}

# Tailscale key for luthien
resource "tailscale_tailnet_key" "luthien_ts" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
  tags          = ["tag:prod"]
}

# cloud-init config to infect luthien with NixOS
data "cloudinit_config" "luthien_init" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    filename     = "nixos-infect.yaml"
    content = sensitive(<<-EOT
#cloud-config
write_files:
    # Lists files to NOT overwrite when infecting
  - path: /etc/NIXOS_LUSTRATE
    permissions: '0600'
    content: |
      etc/tailscale/authkey
    # Pregenerated Tailscale key
  - path: /etc/tailscale/authkey
    permissions: '0600'
    content: "${tailscale_tailnet_key.luthien_ts.key}"
    # Configuration to bootstrap Tailscale, required to log into the instance
  - path: /etc/nixos/tailscale.nix
    permissions: '0644'
    content: ${jsonencode(file("${path.module}/bootstrap/tailscale.nix"))}
runcmd:
    # Remove comment lines from the root user's SSH authorized keys file
  - sed -i 's:#.*$::g' /root/.ssh/authorized_keys
  - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIXOS_IMPORT=./tailscale.nix NIX_CHANNEL=nixos-unstable PROVIDER=digitalocean bash 2>&1 | tee /tmp/infect.log
EOT
    )
  }
}

# Luthien is my main/only cloud server, on DigitalOcean
resource "digitalocean_droplet" "luthien" {
  name          = "luthien"
  size          = "s-1vcpu-2gb"
  image         = "ubuntu-20-04-x64" # Base image, doesn't really matter because we'll infect with NixOS
  region        = "nyc1"
  ipv6          = true
  droplet_agent = false
  tags          = ["nixos"]
  ssh_keys      = [37004965]
  user_data     = data.cloudinit_config.luthien_init.rendered

  provisioner "local-exec" {
    command = "${path.module}/bootstrap/assimilate.sh ${self.name} ${self.ipv4_address}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/hosts/${self.name}"
  }
}

data "local_file" "luthien_ssh_key" {
  depends_on = [
    digitalocean_droplet.luthien
  ]
  filename = "${path.module}/hosts/${digitalocean_droplet.luthien.name}/ssh_pubkey"
}

resource "digitalocean_reserved_ip" "luthien_ip" {
  droplet_id = digitalocean_droplet.luthien.id
  region     = digitalocean_droplet.luthien.region
}

# Default root DNS domain
resource "digitalocean_domain" "default" {
  name = "bennavetta.com"
}

# Records pointing to Luthien
resource "digitalocean_record" "next_ipv4" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "next"
  value  = digitalocean_reserved_ip.luthien_ip.ip_address
}

resource "digitalocean_record" "next_ipv6" {
  domain = digitalocean_domain.default.id
  type   = "AAAA"
  name   = "next"
  # DigitalOcean doesn't support reserved IPV6 addresses, so use the droplet's address
  value = digitalocean_droplet.luthien.ipv6_address
}

resource "digitalocean_domain" "wedding_website" {
  name = "follettnavetta.wedding"
}

resource "digitalocean_record" "wedding_website_ipv4" {
  domain = digitalocean_domain.wedding_website.id
  type   = "A"
  name   = "@"
  value  = digitalocean_reserved_ip.luthien_ip.ip_address
}

resource "digitalocean_record" "wedding_website_ipv6" {
  domain = digitalocean_domain.wedding_website.id
  type   = "AAAA"
  name   = "@"
  value  = digitalocean_droplet.luthien.ipv6_address
}

resource "digitalocean_record" "wedding_website_www" {
  domain = digitalocean_domain.wedding_website.id
  type   = "CNAME"
  name   = "www"
  value  = "@"
}

# Bot keys for private repos accessed by Nix
resource "github_user_ssh_key" "luthien_machine_key" {
  title = "Access key for Luthien"
  key   = data.local_file.luthien_ssh_key.content
}

data "local_file" "faramir_ssh_key" {
  filename = "${path.module}/hosts/faramir/ssh_pubkey"
}

resource "github_user_ssh_key" "faramir_machine_key" {
  title = "Access key for Faramir"
  key   = data.local_file.faramir_ssh_key.content
}
