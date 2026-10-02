variable "aws_region" {
  description = "AWS region (Learner Lab only allows us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for resource names."
  type        = string
  default     = "anitracker"
}

variable "my_ip_cidr" {
  description = "CIDR allowed to SSH into the API instance. Leave empty to auto-detect this machine's public IP."
  type        = string
  default     = ""
}

variable "api_instance_type" {
  description = "EC2 instance type for the API server."
  type        = string
  default     = "t3.small"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "RDS PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "key_name" {
  description = "Existing EC2 key pair for SSH (Learner Lab provides 'vockey')."
  type        = string
  default     = "vockey"
}

variable "instance_profile" {
  description = "Existing IAM instance profile (Learner Lab cannot create IAM roles, so use 'LabInstanceProfile')."
  type        = string
  default     = "LabInstanceProfile"
}
