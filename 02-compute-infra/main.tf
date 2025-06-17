# 02-compute-infra/main.tf

# --- Data Sources to look up existing network resources ---
data "aws_vpc" "selected_vpc" {
  tags = { Name = var.vpc_name_tag_to_lookup }
}
data "aws_subnet" "selected_public_subnet" {
  vpc_id = data.aws_vpc.selected_vpc.id
  tags   = { Name = var.public_subnet_name_tag_to_lookup }
}
data "aws_security_group" "web_app_sg" {
  name   = var.web_app_sg_name_tag_to_lookup
  vpc_id = data.aws_vpc.selected_vpc.id
}
data "aws_security_group" "backend_sg" {
  name   = var.backend_sg_name_tag_to_lookup
  vpc_id = data.aws_vpc.selected_vpc.id
}
data "aws_security_group" "db_sg" {
  name   = var.db_sg_name_tag_to_lookup
  vpc_id = data.aws_vpc.selected_vpc.id
}
data "aws_eip" "web_app_eip" {
  tags = { Name = var.web_app_eip_name_tag_to_lookup }
}

# --- SNS TOPIC FOR COMPUTE ALARMS (Created within this module) ---
resource "aws_sns_topic" "compute_alarms" {
  name = var.compute_sns_topic_name
  tags = {
    Name = var.compute_sns_topic_name 
  }
}
resource "aws_sns_topic_subscription" "compute_email_subscriptions" {
  for_each  = toset(var.compute_alarm_notification_emails)
  topic_arn = aws_sns_topic.compute_alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

# --- EC2 Instances ---
resource "aws_instance" "web_app" {
  ami                          = var.ami_id
  instance_type                = var.web_app_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.web_app_sg.id]
  associate_public_ip_address  = false
  monitoring                   = true 
  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "WEB-APP", Tier = "WebApp" }
}
resource "aws_eip_association" "web_app_eip_assoc" {
  instance_id   = aws_instance.web_app.id
  allocation_id = data.aws_eip.web_app_eip.id
}
resource "aws_instance" "backend" {
  ami                          = var.ami_id
  instance_type                = var.backend_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.backend_sg.id]
  monitoring                   = true
  root_block_device {
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "BACKEND", Tier = "Backend" }
}
resource "aws_instance" "database" {
  ami                          = var.ami_id
  instance_type                = var.db_instance_type
  key_name                     = var.key_pair_name
  subnet_id                    = data.aws_subnet.selected_public_subnet.id
  vpc_security_group_ids       = [data.aws_security_group.db_sg.id]
  monitoring                   = true
  root_block_device {
    volume_size           = 150
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags = { Name = "DATABASE", Tier = "Database" }
}

# ------------------------------------------------------------------------------
# CLOUDWATCH ALARMS
# ------------------------------------------------------------------------------

locals {
  alarm_actions = [aws_sns_topic.compute_alarms.arn]
}

# --- Alarms for WEB-APP Instance ---
# CPU Alarms
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_critical_fast" {
  alarm_name          = "WebApp-CPU-Critical-Fast-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_critical
  alarm_description   = "CRITICAL FAST: EC2 CPU for WEB-APP >= ${var.cpu_threshold_level_critical}%."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_warning" {
  alarm_name          = "WebApp-CPU-Warning-75"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_warning
  alarm_description   = "WARNING: EC2 CPU for WEB-APP >= ${var.cpu_threshold_level_warning}%."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_low_warning" {
  alarm_name          = "WebApp-CPU-Low-Warning-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_low_warning
  alarm_description   = "LOW WARNING: EC2 CPU for WEB-APP >= ${var.cpu_threshold_level_low_warning}%."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_info" {
  alarm_name          = "WebApp-CPU-Info-20"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_info
  alarm_description   = "INFO: EC2 CPU for WEB-APP >= ${var.cpu_threshold_level_info}%."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions # Consider a different SNS topic for info
  ok_actions          = local.alarm_actions 
}

# Memory Alarms (Requires CWAgent configured for 10s metric interval)
resource "aws_cloudwatch_metric_alarm" "web_app_memory_critical_fast" {
  alarm_name          = "WebApp-Memory-Critical-Fast-90"
  # ... (attributes similar to CPU, but with mem_used_percent, CWAgent namespace, fast period)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_critical
  alarm_description   = "CRITICAL FAST: Memory for WEB-APP >= ${var.memory_threshold_level_critical}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "breaching"
}
resource "aws_cloudwatch_metric_alarm" "web_app_memory_warning" {
  alarm_name          = "WebApp-Memory-Warning-75"
  # ...
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_warning
  alarm_description   = "WARNING: Memory for WEB-APP >= ${var.memory_threshold_level_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "web_app_memory_low_warning" {
  alarm_name          = "WebApp-Memory-Low-Warning-50"
  # ...
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_low_warning
  alarm_description   = "LOW WARNING: Memory for WEB-APP >= ${var.memory_threshold_level_low_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "web_app_memory_info" {
  alarm_name          = "WebApp-Memory-Info-20"
  # ...
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_info
  alarm_description   = "INFO: Memory for WEB-APP >= ${var.memory_threshold_level_info}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions # Consider different SNS for info
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}

# Disk and Network Alarms (Critical Level Example)
resource "aws_cloudwatch_metric_alarm" "web_app_disk_write_ops_critical" {
  alarm_name          = "WebApp-Disk-WriteOps-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast 
  metric_name         = "DiskWriteOps" 
  namespace           = "AWS/EC2"      
  period              = var.alarm_period_seconds_standard_ec2_metrics 
  statistic           = "Sum" 
  threshold           = var.disk_write_ops_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Disk Write Ops for WEB-APP is high."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "web_app_network_out_critical" {
  alarm_name          = "WebApp-NetworkOut-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast 
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Sum" 
  threshold           = var.network_out_bytes_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Network Outgoing Bytes for WEB-APP is high."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}


# --- Alarms for BACKEND Instance ---
# CPU Alarms
resource "aws_cloudwatch_metric_alarm" "backend_cpu_critical_fast" {
  alarm_name          = "Backend-CPU-Critical-Fast-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_critical
  alarm_description   = "CRITICAL FAST: EC2 CPU for BACKEND >= ${var.cpu_threshold_level_critical}%."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "backend_cpu_warning" {
  alarm_name          = "Backend-CPU-Warning-75"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_warning
  alarm_description   = "WARNING: EC2 CPU for BACKEND >= ${var.cpu_threshold_level_warning}%."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "backend_cpu_low_warning" {
  alarm_name          = "Backend-CPU-Low-Warning-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_low_warning
  alarm_description   = "LOW WARNING: EC2 CPU for BACKEND >= ${var.cpu_threshold_level_low_warning}%."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "backend_cpu_info" {
  alarm_name          = "Backend-CPU-Info-20"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_info
  alarm_description   = "INFO: EC2 CPU for BACKEND >= ${var.cpu_threshold_level_info}%."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions 
  ok_actions          = local.alarm_actions 
}

# Memory Alarms
resource "aws_cloudwatch_metric_alarm" "backend_memory_critical_fast" {
  alarm_name          = "Backend-Memory-Critical-Fast-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_critical
  alarm_description   = "CRITICAL FAST: Memory for BACKEND >= ${var.memory_threshold_level_critical}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "breaching"
}
resource "aws_cloudwatch_metric_alarm" "backend_memory_warning" {
  alarm_name          = "Backend-Memory-Warning-75"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_warning
  alarm_description   = "WARNING: Memory for BACKEND >= ${var.memory_threshold_level_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "backend_memory_low_warning" {
  alarm_name          = "Backend-Memory-Low-Warning-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_low_warning
  alarm_description   = "LOW WARNING: Memory for BACKEND >= ${var.memory_threshold_level_low_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "backend_memory_info" {
  alarm_name          = "Backend-Memory-Info-20"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_info
  alarm_description   = "INFO: Memory for BACKEND >= ${var.memory_threshold_level_info}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions 
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}

# Disk and Network Alarms
resource "aws_cloudwatch_metric_alarm" "backend_disk_write_ops_critical" {
  alarm_name          = "Backend-Disk-WriteOps-Critical"
  # ... (copy from web_app, change InstanceId)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "DiskWriteOps"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Sum"
  threshold           = var.disk_write_ops_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Disk Write Ops for BACKEND is high."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "backend_network_out_critical" {
  alarm_name          = "Backend-NetworkOut-Critical"
  # ... (copy from web_app, change InstanceId)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Sum"
  threshold           = var.network_out_bytes_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Network Outgoing Bytes for BACKEND is high."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}


# --- Alarms for DATABASE Instance ---
# CPU Alarms
resource "aws_cloudwatch_metric_alarm" "database_cpu_critical_fast" {
  alarm_name          = "Database-CPU-Critical-Fast-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_critical
  alarm_description   = "CRITICAL FAST: EC2 CPU for DATABASE >= ${var.cpu_threshold_level_critical}%."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "database_cpu_warning" {
  alarm_name          = "Database-CPU-Warning-75"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_warning
  alarm_description   = "WARNING: EC2 CPU for DATABASE >= ${var.cpu_threshold_level_warning}%."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "database_cpu_low_warning" {
  alarm_name          = "Database-CPU-Low-Warning-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_low_warning
  alarm_description   = "LOW WARNING: EC2 CPU for DATABASE >= ${var.cpu_threshold_level_low_warning}%."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "database_cpu_info" {
  alarm_name          = "Database-CPU-Info-20"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Average"
  threshold           = var.cpu_threshold_level_info
  alarm_description   = "INFO: EC2 CPU for DATABASE >= ${var.cpu_threshold_level_info}%."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions 
  ok_actions          = local.alarm_actions 
}

# Memory Alarms
resource "aws_cloudwatch_metric_alarm" "database_memory_critical_fast" {
  alarm_name          = "Database-Memory-Critical-Fast-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_critical
  alarm_description   = "CRITICAL FAST: Memory for DATABASE >= ${var.memory_threshold_level_critical}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "breaching"
}
resource "aws_cloudwatch_metric_alarm" "database_memory_warning" {
  alarm_name          = "Database-Memory-Warning-75"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_warning
  alarm_description   = "WARNING: Memory for DATABASE >= ${var.memory_threshold_level_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "database_memory_low_warning" {
  alarm_name          = "Database-Memory-Low-Warning-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_low_warning
  alarm_description   = "LOW WARNING: Memory for DATABASE >= ${var.memory_threshold_level_low_warning}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "database_memory_info" {
  alarm_name          = "Database-Memory-Info-20"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_info_warning
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds_fast_custom_metrics
  statistic           = "Average"
  threshold           = var.memory_threshold_level_info
  alarm_description   = "INFO: Memory for DATABASE >= ${var.memory_threshold_level_info}% (CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions 
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}

# Disk and Network Alarms
resource "aws_cloudwatch_metric_alarm" "database_disk_write_ops_critical" {
  alarm_name          = "Database-Disk-WriteOps-Critical"
  # ... (copy from web_app, change InstanceId)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "DiskWriteOps"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Sum"
  threshold           = var.disk_write_ops_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Disk Write Ops for DATABASE is high."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "database_network_out_critical" {
  alarm_name          = "Database-NetworkOut-Critical"
  # ... (copy from web_app, change InstanceId)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods_fast
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds_standard_ec2_metrics
  statistic           = "Sum"
  threshold           = var.network_out_bytes_threshold_per_second_critical * var.alarm_period_seconds_standard_ec2_metrics
  alarm_description   = "CRITICAL: EC2 Network Outgoing Bytes for DATABASE is high."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}