resource "digitalocean_ssh_key" "default" {
  name       = "Eugene's MacBook"
  public_key = "${file("~/.ssh/id_rsa_do.pub")}"
}
