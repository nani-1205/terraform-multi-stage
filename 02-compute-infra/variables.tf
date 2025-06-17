# 02-compute-infra/variables.tf

variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "me-central-1"
}

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

variable "sns_topic_name_tag_to_lookup" {
  description = "The 'Name' tag of the SNS topic to send alarm notifications to"
  type        = string
  default     = "my-app-alarms-sns-topic"
}

variable "key_pair_name" {
  description = "Name of the EC2 Key Pair for instances"
  type        = string
  default     = "UE"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances"
  type        = string
  default     = "ami-0178175c071ffc9e8" 
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

# --- CloudWatch Alarm Thresholds ---
variable "cpu_utilization_threshold" {
  description = "CPU utilization threshold percentage for alarms"
  type        = number
  default     = 75 
}

variable "memory_utilization_threshold" {
  description = "Memory utilization threshold percentage for alarms (requires CloudWatch Agent)"
  type        = number
  default     = 80 
}

variable "disk_write_ops_threshold_per_second" { # Renamed for clarity
  description = "Disk Write Operations threshold (Count/Second) for alarms"
  type        = number
  default     = 1000 
}

variable "network_out_bytes_threshold_per_second" { # Renamed for clarity
  description = "Network Outgoing Bytes threshold (Bytes/Second) for alarms"
  type        = number
  default     = 500000000 
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate for the alarm state"
  type        = number
  default     = 2
}

variable "alarm_period_seconds" {
  description = "Duration in seconds over which the statistic is applied"
  type        = number
  default     = 300 # 5 minutes
}