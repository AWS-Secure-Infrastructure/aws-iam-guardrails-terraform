variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging and naming"
  type        = string
  default     = "iam-guardrails"
}
