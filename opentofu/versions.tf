terraform {
  required_version = ">= 1.0"

  required_providers {
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "~> 2.0"
    }
  }
}

