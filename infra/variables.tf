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
  description = "Existing EC2 key pair associated with instances for emergency administration."
  type        = string
  default     = "cosc349-2026"
}

variable "repository_url" {
  description = "Public Git repository cloned by both EC2 instances during bootstrap."
  type        = string
  default     = "https://github.com/Hephaestus2nd/Anitracker.git"
}

variable "repository_ref" {
  description = "Git branch or commit checked out by the EC2 bootstrap scripts."
  type        = string
  default     = "main"
}
