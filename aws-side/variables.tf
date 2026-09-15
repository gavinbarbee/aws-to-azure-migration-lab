variable "aws_region" {
  description = "AWS region to deploy the source EC2 instance into."
  type        = string
  default     = "us-east-1"
}
 
variable "yourname" {
  description = "Your name, lowercase, no spaces. Used to make resource names unique."
  type        = string
}
 
variable "windows_ami" {
  description = "Windows Server 2022 Base AMI ID for us-east-1. Update if using a different region."
  type        = string
  default     = "ami-0c2b0d3fb02824d92"
}
 
variable "instance_type" {
  description = "EC2 instance type. t3.medium is the minimum for Windows Server."
  type        = string
  default     = "t3.medium"
}
 
variable "admin_password" {
  description = "Administrator password for the Windows Server instance."
  type        = string
  sensitive   = true
}