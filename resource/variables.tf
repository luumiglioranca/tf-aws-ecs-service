variable "create" {
  type    = bool
  default = true
}
variable "cluster_type" {
  description = "Cluster Type, permite apenas valores FARGATE e EC2. Que são compativeis com o base no tipo que precisa iniciar sua task."
  type        = string
}
variable "cluster_name" {
  description = "O nome do cluster que deseja iniciar"
  type        = string
}
variable "ecs_capacity_providers" {
  type    = any
  default = []
}
variable "capacity_provider_strategy" {
  type    = any
  default = []
}
variable "setting" {
  type    = any
  default = []
}
variable "description" {
  type    = string
  default = null
}
variable "path" {
  type    = string
  default = "/"
}
variable "default_tags" {
  type    = map(any)
  default = {}
}
variable "task_definition" {
  type    = any
  default = []
}
variable "ecs_service" {
  type    = any
  default = []
}
variable "service_auto_scaling" {
  type    = any
  default = []
}
variable "service_load_balancing" {
  type    = any
  default = []
}
variable "service_load_balancing_https" {
  type    = any
  default = []
}
variable "log_driver" {
  type    = any
  default = []
}
variable "cluster_resources" {
  type    = any
  default = []
}
variable "placement_strategy" {
  type    = any
  default = []
}
variable "deployment_controller" {
  type    = any
  default = []
}
variable "placement_constraints" {
  type    = any
  default = []
}
variable "container_definitions" {
  type    = any
  default = []
}
variable "autoscaling_policy" {
  type    = bool
  default = false
}
variable "resource_name" {
  type    = any
  default = []
}
variable "account_id" {
  type    = any
  default = []
}
variable "account_name" {
  type    = any
  default = []
}
variable "ordered_placement_strategy" {
  type    = any
  default = []
}
variable "target_group_settings" {
  type    = any
  default = []
}
