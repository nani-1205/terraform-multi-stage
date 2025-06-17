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

variable "compute_sns_topic_name" {
  description = "Name for the SNS topic for Compute infrastructure alarms."
  type        = string
  default     = "my-app-compute-alarms-topic"
}

variable "compute_alarm_notification_emails" {
  description = "A list of email addresses to subscribe to the Compute SNS alarm topic."
  type        = list(string)
  default     = [
    "prabhakararao.nandigrama@assettl.com",
    "yetukurisaijagan@gmail.com"
  ]
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

# --- CloudWatch Alarm Configuration ---
variable "alarm_evaluation_periods_fast" {
  description = "Number of periods to evaluate for fast alarm state (typically 1)"
  type        = number
  default     = 1
}

variable "alarm_evaluation_periods_info_warning" { 
  description = "Number of periods to evaluate for info/warning alarm state"
  type        = number
  default     = 2 # Can be 1 if you want these fast too, or higher for more stability
}

variable "alarm_period_seconds_fast_custom_metrics" {
  description = "Duration in seconds for fast alarms on custom metrics (e.g., Memory via CWAgent). CWAgent must publish at this rate."
  type        = number
  default     = 10 
}

variable "alarm_period_seconds_standard_ec2_metrics" {
  description = "Duration in seconds for alarms on standard EC2 metrics (min 60 for 1-min resolution)."
  type        = number
  default     = 60 
}

# --- Thresholds ---
variable "cpu_threshold_level_info" { type = number; default = 20 }      # Info
variable "cpu_threshold_level_low_warning" { type = number; default = 50 } # Low Warning
variable "cpu_threshold_level_warning" { type = number; default = 75 }   # Warning
variable "cpu_threshold_level_critical" { type = number; default = 90 }  # Critical

variable "memory_threshold_level_info" { type = number; default = 20 }      # Info (CWAgent)
variable "memory_threshold_level_low_warning" { type = number; default = 50 } # Low Warning (CWAgent)
variable "memory_threshold_level_warning" { type = number; default = 75 }   # Warning (CWAgent)
variable "memory_threshold_level_critical" { type = number; default = 90 }  # Critical (CWAgent)

variable "disk_write_ops_threshold_per_second_critical" { 
  description = "Disk Write Operations critical threshold (Count/Second) for alarms"
  type        = number
  default     = 1000 
}

variable "network_out_bytes_threshold_per_second_critical" { 
  description = "Network Outgoing Bytes critical threshold (Bytes/Second) for alarms"
  type        = number
  default     = 250 * 1024 * 1024 # 250 MB/s
}