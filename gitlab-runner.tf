resource "digitalocean_droplet" "gitlab-runner" {
  image              = "ubuntu-18-04-x64"
  name               = "gitlab-runner"
  region             = "fra1"
  size               = "s-2vcpu-4gb"
  private_networking = true

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

      # create gitlab-runner config directory
      "sudo mkdir /etc/gitlab-runner",

      # register runner
      "sudo docker run --rm -t -i -v /etc/gitlab-runner:/etc/gitlab-runner --name gitlab-runner gitlab/gitlab-runner register --non-interactive --url 'https://gitlab.com/' --registration-token '${var.gitlab_runner_token}' --executor 'docker' --docker-image alpine:3 --description 'docker-runner' --tag-list 'docker' --run-untagged --locked='false' --docker-privileged",

      # start runner
      "docker run -d --name gitlab-runner --restart always -v /etc/gitlab-runner:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner"
    ]
  }
}