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
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_critical" {
  alarm_name          = "WebApp-CPU-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 CPU utilization for WEB-APP is high."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "web_app_cpu_warning" {
  alarm_name          = "WebApp-CPU-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 CPU utilization for WEB-APP is elevated."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions 
}
resource "aws_cloudwatch_metric_alarm" "web_app_memory_critical" {
  alarm_name          = "WebApp-Memory-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent" 
  namespace           = "CWAgent"          
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 Memory utilization for WEB-APP is high (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "web_app_memory_warning" {
  alarm_name          = "WebApp-Memory-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent" 
  namespace           = "CWAgent"          
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 Memory utilization for WEB-APP is elevated (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "web_app_disk_write_ops" {
  alarm_name          = "WebApp-Disk-WriteOps-High"
  # ... (rest of attributes from previous full script)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DiskWriteOps"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.disk_write_ops_threshold_per_second * var.alarm_period_seconds
  alarm_description   = "This metric monitors EC2 Disk Write Ops for WEB-APP."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "web_app_network_out" {
  alarm_name          = "WebApp-NetworkOut-High"
  # ... (rest of attributes from previous full script)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.network_out_bytes_threshold_per_second * var.alarm_period_seconds
  alarm_description   = "This metric monitors EC2 Network Outgoing Bytes for WEB-APP."
  dimensions          = { InstanceId = aws_instance.web_app.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

# --- Alarms for BACKEND Instance ---
resource "aws_cloudwatch_metric_alarm" "backend_cpu_critical" {
  alarm_name          = "Backend-CPU-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 CPU utilization for BACKEND is high."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "backend_cpu_warning" {
  alarm_name          = "Backend-CPU-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 CPU utilization for BACKEND is elevated."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "backend_memory_critical" {
  alarm_name          = "Backend-Memory-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 Memory utilization for BACKEND is high (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "backend_memory_warning" {
  alarm_name          = "Backend-Memory-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 Memory utilization for BACKEND is elevated (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "backend_disk_write_ops" {
  alarm_name          = "Backend-Disk-WriteOps-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DiskWriteOps"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.disk_write_ops_threshold_per_second * var.alarm_period_seconds
  alarm_description   = "This metric monitors EC2 Disk Write Ops for BACKEND."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "backend_network_out" {
  alarm_name          = "Backend-NetworkOut-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.network_out_bytes_threshold_per_second * var.alarm_period_seconds
  alarm_description   = "This metric monitors EC2 Network Outgoing Bytes for BACKEND."
  dimensions          = { InstanceId = aws_instance.backend.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}

# --- Alarms for DATABASE Instance ---
resource "aws_cloudwatch_metric_alarm" "database_cpu_critical" {
  alarm_name          = "Database-CPU-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 CPU utilization for DATABASE is high."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "database_cpu_warning" {
  alarm_name          = "Database-CPU-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 CPU utilization for DATABASE is elevated."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "database_memory_critical" {
  alarm_name          = "Database-Memory-Utilization-Critical"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_critical
  alarm_description   = "CRITICAL: EC2 Memory utilization for DATABASE is high (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "database_memory_warning" {
  alarm_name          = "Database-Memory-Utilization-Warning"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.memory_utilization_threshold_warning
  alarm_description   = "WARNING: EC2 Memory utilization for DATABASE is elevated (requires CWAgent)."
  dimensions          = { InstanceId = aws_instance.database.id }
  alarm_actions       = local.alarm_actions
  ok_actions          = local.alarm_actions
  treat_missing_data  = "missing"
}
resource "aws_cloudwatch_metric_alarm" "database_disk_write_ops" {
  alarm_name          = "Database-Disk-WriteOps-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "DiskWriteOps" 
  namespace           = "AWS/EC2"      
  period              = var.alarm_period_seconds
  statistic           = "Sum" 
  threshold           = var.disk_write_ops_threshold_per_second * var.alarm_period_seconds 
  alarm_description   = "This metric monitors EC2 Disk Write Ops for DATABASE."
  dimensions = { InstanceId = aws_instance.database.id }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
resource "aws_cloudwatch_metric_alarm" "database_network_out" {
  alarm_name          = "Database-NetworkOut-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.alarm_period_seconds
  statistic           = "Sum" 
  threshold           = var.network_out_bytes_threshold_per_second * var.alarm_period_seconds
  alarm_description   = "This metric monitors EC2 Network Outgoing Bytes for DATABASE."
  dimensions = { InstanceId = aws_instance.database.id }
  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}