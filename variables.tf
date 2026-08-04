variable "name" {
  type    = string
  default = null
}

variable "environment" {
  type    = string
  default = "nonprod"
}

variable "kubernetes_version" {
  type    = string
  default = "1.36"
}

variable "region" {
  type    = string
  default = null
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
