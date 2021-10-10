# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token" {}

variable "pub_key" {}

variable "pvt_key" {}

variable "ssh_fingerprint" {}

variable "gitlab_runner_token" {}

variable "environment" {
  default = "staging"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}
