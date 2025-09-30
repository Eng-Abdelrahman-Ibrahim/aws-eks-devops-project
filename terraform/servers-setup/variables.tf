variable "aws_region" {
  description = "AWS region of the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = "engabdelrahman2025@outlook.com"
}