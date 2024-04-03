############################################################################################
#                                                                                          #
#                         CRIAÇÃO DO NOSSO SERVICE (SVC) - CLUSTER ECS                     #
#                                                                                          #
############################################################################################

resource "aws_ecs_service" "main" {
  count = var.create && var.cluster_type == "FARGATE" || var.cluster_type == "EC2" ? length(var.ecs_service) : 0

  depends_on = [
    aws_ecs_task_definition.main
  ]

  name                               = lookup(var.ecs_service[count.index], "service_name", null)
  cluster                            = lookup(var.ecs_service[count.index], "cluster_name", null)
  launch_type                        = lookup(var.ecs_service[count.index], "launch_type", null)
  desired_count                      = lookup(var.ecs_service[count.index], "desired_count", null)
  enable_ecs_managed_tags            = lookup(var.ecs_service[count.index], "managed_tags", null)
  scheduling_strategy                = lookup(var.ecs_service[count.index], "scheduling_strategy", null)
  deployment_minimum_healthy_percent = lookup(var.ecs_service[count.index], "deployment_minimum_healthy_percent", null)
  deployment_maximum_percent         = lookup(var.ecs_service[count.index], "deployment_maximum_percent", null)
  task_definition                    = element(aws_ecs_task_definition.main.*.arn, count.index)
  #platform_version                  = lookup(var.ecs_service[count.index], "platform_version", null)

  ############################################################################################
  #                                                                                          #
  #                         ATACH DO LOAD BALANCER NA NOSSA SVC <3                           #
  #                                                                                          #
  ############################################################################################

  dynamic "load_balancer" {
    for_each = length(keys(lookup(var.ecs_service[count.index], "load_balancer", {}))) == 0 ? [] : [lookup(var.ecs_service[count.index], "load_balancer", {})]

    content {
      target_group_arn = lookup(load_balancer.value, "target_group_arn", null)
      container_name   = lookup(load_balancer.value, "container_name", null)
      container_port   = lookup(load_balancer.value, "container_port", null)
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = lookup(var.ecs_service[count.index], "ordered_placement_strategy", var.ordered_placement_strategy)

    content {
      type  = lookup(ordered_placement_strategy.value, "type", null)
      field = lookup(ordered_placement_strategy.value, "field", null)
    }
  }

  ############################################################################################
  #                                                                                          #
  #         PLACEMENT CONSTRAINTS PARA MÚLTIPLAS ZONAS DE DISPONIBILIDADE (A, B OU C)        #
  #                                                                                          #
  ############################################################################################

  dynamic "placement_constraints" {
    for_each = lookup(var.ecs_service[count.index], "placement_constraints", var.placement_constraints)

    content {
      type       = lookup(placement_constraints.value, "type", null)
      expression = lookup(placement_constraints.value, "expression", null)
    }
  }

  ############################################################################################
  #                                                                                          #
  #                 CAPACITY PROVIDER PARA A SVC (POR PADRÃO SUBIMOS COMO EC2)               #
  #                                                                                          #
  ############################################################################################

  dynamic "capacity_provider_strategy" {
    for_each = lookup(var.ecs_service[count.index], "capacity_provider_strategy", var.capacity_provider_strategy)
    content {
      capacity_provider = lookup(capacity_provider_strategy.value, "capacity_provider", null)
      base              = lookup(capacity_provider_strategy.value, "base", null)
      weight            = lookup(capacity_provider_strategy.value, "weight", null)
    }
  }

  /*dynamic "network_configuration" {
        for_each = length(keys(lookup(var.ecs_service[count.index], "network_configuration", {}))) == 0 ? [] : [lookup(var.ecs_service[count.index], "network_configuration", {})]
        content {
            subnets             = lookup(network_configuration.value, "subnets", null)
            assign_public_ip    = lookup(network_configuration.value, "assign_public_ip", "false")
            security_groups     = lookup(network_configuration.value, "security_groups", null)
        }
    }*/

  lifecycle {
    ignore_changes = [desired_count]
  }
}

############################################################################################
#                                                                                          #
#                          AUTO SCALLING FOR SERVICE - TARGET + POLICY                     #
#                                                                                          # 
############################################################################################

resource "aws_appautoscaling_target" "main" {
  count = var.create && var.cluster_type == "FARGATE" || var.cluster_type == "EC2" ? length(var.service_auto_scaling) : 0

  depends_on = [aws_ecs_service.main]

  role_arn           = lookup(var.service_auto_scaling[count.index], "role_arn", null)
  min_capacity       = lookup(var.service_auto_scaling[count.index], "min_capacity", null)
  max_capacity       = lookup(var.service_auto_scaling[count.index], "max_capacity", null)
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.main.0.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  count = var.create && var.cluster_type == "FARGATE" || var.cluster_type == "EC2" ? length(var.service_auto_scaling) : 0

  name        = "${aws_ecs_service.main.0.name}-svc-auto-scaling"
  policy_type = lookup(var.service_auto_scaling[count.index], "policy_type", null)

  resource_id        = aws_appautoscaling_target.main.0.resource_id
  scalable_dimension = aws_appautoscaling_target.main.0.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main.0.service_namespace

  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = length(keys(lookup(var.service_auto_scaling[count.index], "target_scaling_policy", {}))) == 0 ? [] : [lookup(var.service_auto_scaling[count.index], "target_scaling_policy", {})]
    content {
      target_value       = lookup(target_tracking_scaling_policy_configuration.value, "target_value", null)
      scale_in_cooldown  = lookup(target_tracking_scaling_policy_configuration.value, "cooldown_for_scale_in", null)
      scale_out_cooldown = lookup(target_tracking_scaling_policy_configuration.value, "cooldown_for_scale_out", null)

      dynamic "predefined_metric_specification" {
        for_each = length(keys(lookup(target_tracking_scaling_policy_configuration.value, "metric_specification", {}))) == 0 ? [] : [lookup(target_tracking_scaling_policy_configuration.value, "metric_specification", {})]
        content {
          predefined_metric_type = lookup(predefined_metric_specification.value, "metric_type", null)
        }
      }
    }
  }

  depends_on = [aws_ecs_service.main]

}

############################################################################################
#                                                                                          #
#                        CRIAÇÃO DA NOSSA TASK DEFINITION WONDERFUL <3                     #
#                                                                                          # 
############################################################################################

resource "aws_ecs_task_definition" "main" {
  #depends_on = [aws_ecs_service.main, aws_iam_role.main]

  count = var.create && var.cluster_type == "FARGATE" || var.cluster_type == "EC2" ? length(var.task_definition) : 0

  family                   = lookup(var.task_definition[count.index], "family", null)
  cpu                      = lookup(var.task_definition[count.index], "cpu", null)
  memory                   = lookup(var.task_definition[count.index], "memory", null)
  network_mode             = lookup(var.task_definition[count.index], "network_mode", null)
  requires_compatibilities = lookup(var.task_definition[count.index], "requires_compatibilities", null)
  container_definitions    = lookup(var.task_definition[count.index], "container_definitions", var.container_definitions)
  task_role_arn            = lookup(var.task_definition[count.index], "task_role_arn", null)
  execution_role_arn       = lookup(var.task_definition[count.index], "execution_role_arn", null)

  tags = var.default_tags

}