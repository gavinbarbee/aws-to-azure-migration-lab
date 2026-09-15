variable "yourname" {
  type = string
}
 
variable "location" {
  description = "Azure region for target resources. Choose a region close to your AWS region."
  type        = string
  default     = "East US"
}
 
variable "tags" {
  type = map(string)
  default = {
    project    = "azure-migrate-lab"
    managed_by = "terraform"
  }
}
 variable "appliance_admin_password" {
  description = "Admin password for the appliance VM."
  type        = string
  sensitive   = true
}

variable "replication_admin_password" {
  description = "Admin password for the replication appliance VM."
  type        = string
  sensitive   = true
}