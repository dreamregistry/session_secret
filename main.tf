terraform {
  backend "s3" {}

  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "random" {}

resource "random_pet" "namespace" {}

locals {
  parameter_key = "/session_secret/${random_pet.namespace.id}"
}

resource "terraform_data" "set_password" {
  triggers_replace = [
    local.parameter_key,
  ]
  provisioner "local-exec" {
    command = templatefile("${path.module}/set_secret.tpl", {
      parameterKey = local.parameter_key,
    })
  }

  provisioner "local-exec" {
    when    = destroy
    command = templatefile("${path.module}/delete_secret_parameter.tpl", {
      parameterKey = self.triggers_replace[0],
    })
  }
}

data "aws_region" "current" {}

output "SESSION_SECRET" {
  value = {
    type   = "ssm"
    key    = local.parameter_key
    region = data.aws_region.current.name
  }
}

