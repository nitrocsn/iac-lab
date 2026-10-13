variable "region" {
  description = "Region AWS ou creer les ressources"
  type        = string
  default     = "eu-north-1"
}

variable "nombre_vm" {
  description = "Nombre de serveurs web a creer"
  type        = number
  default     = 1
}

variable "type_instance" {
  description = "Gabarit des VM"
  type        = string
  default     = "t3.micro"
}

variable "prefixe_nom" {
  description = "Debut du nom des VM"
  type        = string
  default     = "srv-web"
}

variable "cidr_admin" {
  description = "Adresse autorisee a se connecter en SSH et HTTP"
  type        = string
}
