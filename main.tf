resource "digitalocean_droplet" "docker_swarm_manager" {
  image              = "ubuntu-18-04-x64"
  name               = "waves-voting-${var.environment}-docker-manager"
  region             = "fra1"
  size               = "s-2vcpu-4gb"
  private_networking = true
  tags               = ["${var.environment}"]

  ssh_keys = [
    "${var.ssh_fingerprint}",
  ]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file(var.pvt_key)}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",

      # install docker
      "sudo apt-get update",

      # install the linux-image-extra-* packages, which allow Docker to use the aufs storage drivers
      "sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual",

      # install packages to allow apt to use a repository over HTTPS
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common",

      # add Docker’s official GPG key
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",

      # add LSB modules
      "sudo apt-get -y install lsb-core",

      # set up the stable repository
      # TODO: xential is actual only for do ubuntu distribution, must be taken with $(lsb_release -ce) command
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",

      # update the apt package index
      "sudo apt-get update",

      # make sure you are about to install from the Docker repo instead of the default Ubuntu repo
      "apt-cache policy docker-ce",

      # install docker
      "sudo apt-get -y install docker-ce",

      # check docker installation
      "sudo docker run hello-world",

      # set up filrewall rules for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      "ufw reload",
      "ufw --forse enable",
      "systemctl restart docker",

      # set up docker swarm manager
      "docker swarm init --advertise-addr ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}"
    ]
  }

  provisioner "local-exec" {
    # add remote docker engine to docker-machine
    command = "docker-machine create --driver generic --generic-ip-address ${digitalocean_droplet.docker_swarm_manager.ipv4_address} --generic-ssh-key ${var.pvt_key} ${var.environment}-docker-manager"
  }
}

data "external" "swarm_join_token" {
  program = ["./get-join-tokens.sh"]
  query = {
    host = "${digitalocean_droplet.docker_swarm_manager.ipv4_address}"
  }
}

resource "digitalocean_droplet" "docker-swarm-worker-1" {
  image              = "ubuntu-18-04-x64"
  name               = "waves-voting-${var.environment}-docker-worker-1"
  region             = "fra1"
  size               = "s-2vcpu-4gb"
  private_networking = true
  tags               = ["${var.environment}"]

  ssh_keys = [
    "${var.ssh_fingerprint}",
  ]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file(var.pvt_key)}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",

      # install docker
      "sudo apt-get update",

      # install the linux-image-extra-* packages, which allow Docker to use the aufs storage drivers
      "sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual",

      # install packages to allow apt to use a repository over HTTPS
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common",

      # add Docker’s official GPG key
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",

      # add LSB modules
      "sudo apt-get -y install lsb-core",

      # set up the stable repository
      # TODO: xential is actual only for do ubuntu distribution, must be taken with $(lsb_release -ce) command
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",

      # update the apt package index
      "sudo apt-get update",

      # make sure you are about to install from the Docker repo instead of the default Ubuntu repo
      "apt-cache policy docker-ce",

      # install docker
      "sudo apt-get -y install docker-ce",

      # check docker installation
      "sudo docker run hello-world",

      # set up filrewall rules for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      "ufw reload",
      "ufw --forse enable",
      "systemctl restart docker",

      # add worker node
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}:2377"
    ]
  }

  provisioner "local-exec" {
    # add remote docker engine to docker-machine
    command = "docker-machine create --driver generic --generic-ip-address ${digitalocean_droplet.docker-swarm-worker-1.ipv4_address} --generic-ssh-key ${var.pvt_key} ${var.environment}-docker-worker-1"
  }
}

resource "digitalocean_droplet" "docker-swarm-worker-2" {
  image              = "ubuntu-18-04-x64"
  name               = "waves-voting-${var.environment}-docker-worker-2"
  region             = "fra1"
  size               = "s-2vcpu-4gb"
  private_networking = true
  tags               = ["${var.environment}"]

  ssh_keys = [
    "${var.ssh_fingerprint}",
  ]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file(var.pvt_key)}"
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",

      # install docker
      "sudo apt-get update",

      # install the linux-image-extra-* packages, which allow Docker to use the aufs storage drivers
      "sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual",

      # install packages to allow apt to use a repository over HTTPS
      "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common",

      # add Docker’s official GPG key
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",

      # add LSB modules
      "sudo apt-get -y install lsb-core",

      # set up the stable repository
      # TODO: xential is actual only for do ubuntu distribution, must be taken with $(lsb_release -ce) command
      "sudo add-apt-repository 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable'",

      # update the apt package index
      "sudo apt-get update",

      # make sure you are about to install from the Docker repo instead of the default Ubuntu repo
      "apt-cache policy docker-ce",

      # install docker
      "sudo apt-get -y install docker-ce",

      # check docker installation
      "sudo docker run hello-world",

      # set up filrewall rules for docker swarm
      "ufw allow 22/tcp",
      "ufw allow 2376/tcp",
      "ufw allow 2377/tcp",
      "ufw allow 7946/tcp",
      "ufw allow 7946/udp",
      "ufw allow 4789/udp",
      "ufw reload",
      "ufw --forse enable",
      "systemctl restart docker",

      # add worker node
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}:2377"
    ]
  }

  provisioner "local-exec" {
    # add remote docker engine to docker-machine
    command = "docker-machine create --driver generic --generic-ip-address ${digitalocean_droplet.docker-swarm-worker-2.ipv4_address} --generic-ssh-key ${var.pvt_key} ${var.environment}-docker-worker-2"
  }
}

# # Create a new TLS certificate
# resource "digitalocean_certificate" "staging-cert" {
#   name              = "Trustamust staging cert"
#   type              = "lets_encrypt"
#   domains           = ["www.mvp.trustamust.com","mvp.trustamust.com"]
# }

# Create a new Load Balancer with TLS termination
resource "digitalocean_loadbalancer" "staging-lb" {
  name        = "staging-loadbalancer-1"
  region      = "fra1"
  droplet_tag = "${var.environment}"

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"

    target_port     = 80
    target_protocol = "http"

    entry_port      = 80
    entry_protocol  = "http"

    target_port     = 8081
    target_protocol = "http"

    # certificate_id  = "${digitalocean_certificate.staging-cert.id}"
  }

  healthcheck {
    port = 80
    protocol = "http"
    path = "health"
  }
}
