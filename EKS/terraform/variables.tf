#EKS/terraform/variables.tf

variable "eks_region" {
  description = "AWS region of the EKS cluster"
  type        = string
  default     = "us-east-1"   # or your region
}
