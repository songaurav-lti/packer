packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "ami_prefix" {
  type    = string
  default = "learn-packer-hcp-nginx"
}

data "hcp-packer-iteration" "golden" {
  bucket_name     = "learn-packer-hcp-golden-base-image"
  channel         = "production"
}

data "hcp-packer-image" "golden_base_east" {
  bucket_name     = data.hcp-packer-iteration.golden.bucket_name
  iteration_id    = data.hcp-packer-iteration.golden.id
  cloud_provider  = "aws"
  region          = "us-east-2"
}

data "hcp-packer-image" "golden_base_west" {
  bucket_name      = data.hcp-packer-iteration.golden.bucket_name
  iteration_id     = data.hcp-packer-iteration.golden.id
  cloud_provider   = "aws"
  region           = "us-west-2"
}

locals {
  timestamp           = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "nginx_east" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-east-2"
  source_ami    = data.hcp-packer-image.golden_base_east.id
  ssh_username = "ubuntu"
  tags = {
    Name          = "learn-hcp-packer-nginx-east"
    environment   = "production"
  }
  snapshot_tags = {
    environment   = "production"
  }
}

source "amazon-ebs" "nginx_west" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t2.micro"
  region        = "us-west-2"
  source_ami    = data.hcp-packer-image.golden_base_west.id
  ssh_username = "ubuntu"
  tags = {
    Name          = "learn-hcp-packer-nginx-west"
    environment   = "production"
  }
  snapshot_tags = {
    environment   = "production"
  }
}

build {
  name = "learn-packer-nginx"
  sources = [
    "source.amazon-ebs.nginx_east",
    "source.amazon-ebs.nginx_west"
  ]

  # Add SSH public key
  provisioner "file" {
    source      = "../learn-packer.pub"
    destination = "/tmp/learn-packer.pub"
  }

  # Add Nginx configuration file
  provisioner "file" {
    source      = "custom-nginx.conf"
    destination = "custom-nginx.conf"
  }

  # Add Docker Compose file
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "docker-compose.yml"
  }

  # Add startup script that will run Nginx on instance boot
  provisioner "file" {
    source      = "start-nginx.sh"
    destination = "/tmp/start-nginx.sh"
  }

  # Move temp files to actual destination
  # Must use this method because their destinations are protected 
  provisioner "shell" {
    inline = [
      "sudo cp /tmp/start-nginx.sh /var/lib/cloud/scripts/per-boot/start-nginx.sh",
    ]
  }

  # HCP Packer settings
  hcp_packer_registry {
    bucket_name = "learn-packer-hcp-nginx-image"
    description = <<EOT
This is an image for nginx built on top of a golden base image.
    EOT

    bucket_labels = {
      "hashicorp-learn" = "learn-packer-hcp-nginx-image",
    }
  }
}