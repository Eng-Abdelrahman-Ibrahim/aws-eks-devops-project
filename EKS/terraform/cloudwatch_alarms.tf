# EKS/terraform/cloudwatch_alarms.tf

# ---------------------
# Data source: Find ASG for worker nodes (names always start with myapp-nodes)
# ---------------------
data "aws_autoscaling_groups" "eks_nodegroups" {
  filter {
    name   = "tag:kubernetes.io/cluster/myapp-eks"
    values = ["owned"]
  }
}

# SNS Topic
resource "aws_sns_topic" "eks_alerts" {
  name = "eks-alerts-topic"
}

# Subscription (email)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.eks_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ---------------------
# CloudWatch Alarms for EKS worker nodes
# ---------------------

# High CPU alarm (EC2-level, per ASG)
resource "aws_cloudwatch_metric_alarm" "worker_cpu_high" {
  alarm_name          = "EKS-WorkerNodes-HighCPU-EC2"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when EC2 CPU exceeds 70% for 10 minutes"
  alarm_actions       = [aws_sns_topic.eks_alerts.arn] # Add SNS topic ARN here for email alerts

  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_groups.eks_nodegroups.names[0]
  }
}

# High Memory usage alarm (from CWAgent)
resource "aws_cloudwatch_metric_alarm" "worker_mem_high" {
  alarm_name          = "EKS-WorkerNodes-HighMemory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when average memory usage exceeds 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.eks_alerts.arn]

  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_groups.eks_nodegroups.names[0]
  }
}

# High Disk usage alarm (root volume, from CWAgent)
resource "aws_cloudwatch_metric_alarm" "worker_disk_high" {
  alarm_name          = "EKS-WorkerNodes-HighDisk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alarm when root disk usage exceeds 85% for 10 minutes"
  alarm_actions       = [aws_sns_topic.eks_alerts.arn]

  dimensions = {
    path                 = "/"
    AutoScalingGroupName = data.aws_autoscaling_groups.eks_nodegroups.names[0]
  }
}

# ---------------------
# CloudWatch Dashboard for EKS worker nodes
# ---------------------
resource "aws_cloudwatch_dashboard" "eks_nodes_dashboard" {
  dashboard_name = "EKS-Nodes-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "CWAgent", "cpu_usage_idle", "AutoScalingGroupName", data.aws_autoscaling_groups.eks_nodegroups.names[0] ],
            [ ".", "cpu_usage_user", ".", "." ],
            [ ".", "cpu_usage_system", ".", "." ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.eks_region
          title   = "CPU Usage % (per instance)"
          period  = 60
        }
      },
      {
        type = "metric"
        x    = 12
        y    = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [ "CWAgent", "mem_used_percent", "AutoScalingGroupName", data.aws_autoscaling_groups.eks_nodegroups.names[0] ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.eks_region
          title   = "Memory Used % (per instance)"
          period  = 60
        }
      },
      {
        type = "metric"
        x    = 0
        y    = 6
        width  = 24
        height = 6
        properties = {
          metrics = [
            [ "CWAgent", "used_percent", "AutoScalingGroupName", data.aws_autoscaling_groups.eks_nodegroups.names[0], "path", "/" ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.eks_region
          title   = "Disk Used % (root /)"
          period  = 60
        }
      }
    ]
  })
}
