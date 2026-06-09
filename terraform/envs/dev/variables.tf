variable "ami_id" {
  type    = string
  default = null
}

variable "tailscale_auth_key" {
  description = "Tailscale Auth Key for Subnet Router"
  type        = string
  sensitive   = true
}