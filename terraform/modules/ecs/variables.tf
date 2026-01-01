# TODO: Define input variables for ECS module
#
# Phase 2 implementation will include:
# - variable "cluster_name" { type = string }
# - variable "environment" { type = string }
# - variable "task_cpu" { type = string, description = "256, 512, 1024, etc." }
# - variable "task_memory" { type = string, description = "512, 1024, 2048, etc." }
# - variable "desired_count" { type = number }
# - variable "min_capacity" { type = number }
# - variable "max_capacity" { type = number }
# - variable "ecr_image_uri" { type = string }
# - variable "vpc_id" { type = string }
# - variable "public_subnet_ids" { type = list(string) }
# - variable "private_subnet_ids" { type = list(string) }
# - variable "alb_security_group_id" { type = string }
# - variable "ecs_security_group_id" { type = string }
# - variable "task_execution_role_arn" { type = string }
# - variable "task_role_arn" { type = string }
# - variable "tags" { type = map(string), default = {} }
