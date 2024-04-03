#############################################################################
#                                                                           #
#       IAM ROLES E POLICES PARA A TASK DEFINITION BRABA DAS BRABA <3       #
#                                                                           #
#############################################################################

resource "aws_iam_role" "iam_role_tf" {
  name               = "${local.resource_name}-TaskRole"
  assume_role_policy = data.aws_iam_policy_document.policy_document.json
  path               = "/"
  description        = local.description
  tags               = local.default_tags
}

#############################################################################
#                                                                           #
#       IAM Policy - Criação da policy responsável pelo assume-role         #
#                                                                           #
#############################################################################

data "aws_iam_policy_document" "policy_document" {
  statement {

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }
}

#############################################################################
#                                                                           #
#                       POLICY BRABA DAS BRABA <3 [TASK]                    #
#                                                                           #
#############################################################################

resource "aws_iam_policy" "iam_policy_tf" {

  name = "${local.resource_name}-Task-Policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Effect = "Allow"

        Resource = "*"
      },
    ]
  })

  path        = "/"
  description = "IAM Policy para o ${local.resource_name}-Task-Policy"
}

data "aws_iam_policy" "iam_policy_tf" {

  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#############################################################################
#                                                                           #
#                               POLICY ATTACHMENT                           #
#                                                                           #
#############################################################################

resource "aws_iam_role_policy_attachment" "iam_attachment" {

  role       = aws_iam_role.iam_role_tf.name
  policy_arn = aws_iam_policy.iam_policy_tf.arn
}

resource "aws_iam_role_policy_attachment" "iam_attachment_parameter_group" {

  role       = aws_iam_role.iam_role_tf.name
  policy_arn = "arn:aws:iam::${local.account_id}:policy/Access-Parameter-Group"
}

############################################################################################
#                                                                                          #
#                                     AssumeRole (IAM ROLE)                                #
#                                                                                          # 
############################################################################################

resource "aws_iam_role" "ecs_autoscale_role" {
  name = "ecs-scale-application-${local.resource_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs.application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-autoscale" {
  role       = aws_iam_role.ecs_autoscale_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}
