# AWS Terraform - ECS Service + Task Definition + Components
Este módulo irá provisionar os seguintes recursos:

1: [ECS Service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)

2: [Task Definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_task_definition)

3: [CloudWatch Log Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)

4: [IAM policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)

5: [IAM role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

6: [Attaches a Managed IAM Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)

7: [Route53 record resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)

8: [Elastic Container Registry Repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)

9: [AutoScaling Policy ](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_policy)

10: [AutoScaling Scalable Target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/appautoscaling_target)

11: [Security group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)

12: [Security Group Rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)


**_Importante:_** A documentação da haschicorp é bem completa, se quiserem dar uma olhada, segue o link do glossário com todos os recursos do terraform: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## Exemplo de um module pré-configurado :)
`Lembrando`: Este recurso precisa ter os módulos de ECR, SG e ALB no corpo do código para funcionar, ok?

```bash

############################################################################################
#                                                                                          #
#                        MÓDULO PARA A CRIAÇÃO DA NOSSA SVC SERVICE :)                     #
#                                                                                          # 
############################################################################################

module "ecs_service" {
  source       = "git@github.com:luumiglioranca/tf-aws-ecs-service.git//resource"
  cluster_name = local.cluster_name
  cluster_type = local.launch_type

  ecs_service = [{
    service_name                       = "svc-${local.resource_name}"
    cluster_name                       = "${local.cluster_name}"
    launch_type                        = "${local.launch_type}"
    desired_count                      = "${local.desired_count}"
    scheduling_strategy                = "${local.scheduling_strategy}"
    deployment_minimum_healthy_percent = "${local.deployment_minimum_healthy_percent}"
    maximum_healthy_percent            = "${local.maximum_healthy_percent}"
    managed_tags                       = "true"

    load_balancer = {
      target_group_arn = "${local.target_group_arn}"
      container_name   = "container-${local.resource_name}"
      container_port   = "${local.container_port}"
    }
  }]

  # A seguinte estratégia bin empacota tarefas com base no cpu.
  # Deixando um numero menor de cpu utilizado.

  ordered_placement_strategy = [
    {
      # Distribui Task uniformemente em todas as AZ's.
      type  = "spread"
      field = "attribute:ecs.availability-zone"
    },
    {
      # A seguinte estratégia bin empacota tarefas com base no cpu.
      # Deixando um numero menor de cpu utilizado.
      type  = "binpack"
      field = "cpu"
    }
  ]

  placement_constraints = [
    {
      type       = "memberOf"
      expression = "attribute:ecs.availability-zone in [${local.availability_zones}]"
    }
  ]

  service_auto_scaling = [{
    role_arn     = aws_iam_role.ecs_autoscale_role.arn
    min_capacity = "${local.min_capacity}"
    max_capacity = "${local.max_capacity}"
    policy_type  = "TargetTrackingScaling"

    target_scaling_policy = {
      target_value           = "${local.target_value}"
      cooldown_for_scale_in  = "${local.cooldown_for_scale_in}"
      cooldown_for_scale_out = "${local.cooldown_for_scale_out}"

      metric_specification = { metric_type = "ECSServiceAverageCPUUtilization" }
    }
  }]

  #capacity_provider_strategy = [
  #  {
  #    capacity_provider = "CP-CAPACITY"
  #    base              = "0"
  #    weight            = "1"
  #  }
  #]

  task_definition = [
    {
      family                   = "task-${local.resource_name}"
      cpu                      = "${local.container_cpu}"
      memory                   = "${local.container_memory}"
      network_mode             = "${local.network_mode}"
      requires_compatibilities = [local.launch_type]
      task_role_arn            = aws_iam_role.iam_role_tf.arn
      execution_role_arn       = aws_iam_role.iam_role_tf.arn

      container_definitions = jsonencode([
        {
          name      = "container-${local.resource_name}"
          image     = "${tolist(module.ecr_repository.repo_url)[0]}:${local.image_tags}"
          cpu       = 256
          memory    = 512
          essential = true
          portMappings = [
            {
              containerPort = 3333
              "protocol" : "tcp"
          }]

          "environment" : [{

            "name" : "Ambiente", "value" : "${local.default_tags.Ambiente}",
            "name" : "Area", "value" : "${local.default_tags.Area}"
            "name" : "SubArea", "value" : "${local.default_tags.SubArea}"
          }]

          "logConfiguration" : {
            "logDriver" : "awslogs",
            "options" : {
              "awslogs-group" : "/${local.account_name}/${local.cluster_name}/${local.resource_name}",
              "awslogs-region" : "${local.region}",
              "awslogs-stream-prefix" : "${local.resource_name}"
            }

          }

          log_driver = [{
            log_name          = "/${local.account_name}/ecs-${local.cluster_name}/svc-${local.resource_name}"
            retention_in_days = "${local.cloudwatch_retention}"
            default_tags      = local.default_tags
          }]

        }
      ])

      placement_constraints = {
        type       = "memberOf"
        expression = "attribute:ecs.availability-zone in [${local.availability_zones}]"
      }
    }
  ]
}

############################################################################################
#                                                                                          #
#                           LOG GROUP DO NOSSO QUERIDO CLOUDWATCH                          #
#                                                                                          #
############################################################################################

resource "aws_cloudwatch_log_group" "main" {
  name              = "/${local.account_name}/${local.cluster_name}/svc-${local.resource_name}"
  retention_in_days = local.cloudwatch_retention
  tags              = local.default_tags

  # depends_on = [ aws_iam_role.main ]
}

############################################################################################
#                                                                                          #
#                         MÓDULO PARA CRIAÇÃO DO SECURITY GROUP :)                         #
#                                                                                          #
############################################################################################

module "security_group" {

  source = "git@github.com:luumiglioranca/tf-aws-security-group.git//resource"

  description         = "Security Group para o ${local.resource_name} :)"
  security_group_name = "${local.resource_name}-sg"
  vpc_id              = data.aws_vpc.main.id

  ingress_rule = [
    {
      description = "${local.description}"
      type        = "${local.security_group_type}"
      from_port   = "${local.from_port}"
      to_port     = "${local.to_port}"
      protocol    = "${local.tcp_protocol}"
      cidr_blocks = [data.aws_vpc.main.cidr_block]
    },
    {
      description = "VPN"
      type        = "${local.security_group_type}"
      from_port   = "${local.from_port}"
      to_port     = "${local.to_port}"
      protocol    = "${local.tcp_protocol}"
      cidr_blocks = ["x.x.x.x/x"]
    }
  ]

  default_tags = merge({

    Name = "sg-${local.resource_name}"

    },

    local.default_tags

  )
}

#################################################################################################
#                                                                                               #
#                  MÓDULO PARA A CRIAÇÃO DO ECR REPOSITORY - ECS CLUSTER [EC2]                  #
#                                                                                               #
#################################################################################################

module "ecr_repository" {
  source = "git@github.com:luumiglioranca/tf-aws-ecr-repository.git//resource"

  name_repo            = local.resource_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration = [{
    scan_on_push = "true"
  }]

  #docker_source_path  = "docker-image/"
  #docker_image_name     = local.resource_name
  #docker_image_tag      = local.image_tags

  lifecycle_policy = [
    {
      rulePriority      = "1"
      ruleActionType    = "expire"
      ruleDescription   = "Keep last 30 images"
      ruleTagStatus     = "tagged"
      ruleTagPrefixList = "v"
      ruleCountType     = "imageCountMoreThan"
      ruleCountUnit     = "days"
      ruleCountNumber   = "30"
    }
  ]

  default_tags = local.default_tags

}

```

## Para executar esse módulo você precisará: 

| Name | Version|
|------|--------|
| aws | 3.* |
| terraform | 0.15.*| 
| github | 3.3.*


## Arquivo de Outputs

| Name | Description |
| ---- | ----------- |
| ecs_service | dns que será provisionaodo para o ALB na conta atena|


## Espero que seja útil a todos!!!!! Grande abraço <3


**_Importante:_** Qualquer dificuldade encontrada, melhoria ou se precisarem alterar alguma linha de código, só entrar em contato que te ajudo <3

