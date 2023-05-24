terraform {
  backend "s3" {}

  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.4"
    }

    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "random" {}
provider "aws" {}

resource "random_pet" "namespace" {}

resource "random_password" "secret" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "secret" {
  name        = "/session_secret/v2/${random_pet.namespace.id}"
  description = "Session secret value"
  type        = "SecureString"
  value       = random_password.secret.result
}

resource "terraform_data" "set_password" {
  triggers_replace = []

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
    key    = aws_ssm_parameter.secret.name
    region = data.aws_region.current.name
    arn    = aws_ssm_parameter.secret.arn
  }
}

