# 02-compute-infra/variables.tf

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "me-central-1"
}

# --- Variables for looking up Network Resources by Name Tag ---
# These should match the *Name tag values* used in the 01-network-infra script
variable "vpc_name_tag_to_lookup" {
  description = "The 'Name' tag of the VPC to use"
  type        = string
  default     = "my-app-vpc" 
}

variable "public_subnet_name_tag_to_lookup" {
  description = "The 'Name' tag of the Public Subnet to use"
  type        = string
  default     = "my-app-public-subnet"
}

variable "web_app_sg_name_tag_to_lookup" {
  description = "The 'Name' tag of the Web App Security Group to use"
  type        = string
  default     = "my-app-web-app-sg"
}

variable "backend_sg_name_tag_to_lookup" {
  description = "The 'Name' tag of the Backend Security Group to use"
  type        = string
  default     = "my-app-backend-sg"
}

variable "db_sg_name_tag_to_lookup" {
  description = "The 'Name' tag of the Database Security Group to use"
  type        = string
  default     = "my-app-db-sg"
}

variable "web_app_eip_name_tag_to_lookup" {
  description = "The 'Name' tag of the Web App Elastic IP to use"
  type        = string
  default     = "WEB-APP-EIP"
}

# --- EC2 Instance Configuration ---
variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for instances"
  type        = string
  default     = "UE"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0178175c071ffc9e8" # Amazon Linux 2 in me-central-1
}

variable "web_app_instance_type" {
  description = "Instance type for WEB-APP"
  type        = string
  default     = "t3.large"
}

variable "backend_instance_type" {
  description = "Instance type for BACKEND"
  type        = string
  default     = "t3.large"
}

variable "db_instance_type" {
  description = "Instance type for DATABASE"
  type        = string
  default     = "t3.xlarge"
}