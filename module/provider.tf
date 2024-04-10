########################################################################################################
#                                                                                                      #
#                                     CONNECT PROVIDER - AWS    :)                                     #
#                                                                                                      #
########################################################################################################

provider "aws" {
  #Região onde será configurado seu recurso. Deixei us-east-1 como default
  region = "us-east-1"

  #Conta mãe que será responsável pelo provisionamento do recurso.
  profile = ""

  #Assume Role necessária para o provisionamento de recurso, caso seja via role.
  assume_role {
    role_arn = "" #Role que será assumida pela sua conta principal :)
  }
}

#Configurações de backend, neste caso para armazenar o estado do recurso via Bucket S3.
terraform {
  backend "s3" {
    #Profile (conta) de onde está o bucket que você irá armazenar seu tfstate 
    profile = ""

    #Nome do Bucket
    bucket = ""

    #Caminho da chave para o recurso que será criado
    key = "caminho-da-chave/exemplo/terraform.tfstate"

    #Região onde será configurado seu recurso. Deixei us-east-1 como default
    region = "us-east-1"

    #Valores de segurança. Encriptação, Validação de credenciais e Check da API.
    encrypt                     = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
  }
}

########################################################################################################
#                                                                                                      #
#                                     DECLARAÇÃO DE VARIÁVEIS LOCAIS   :)                              #
#                                                                                                      #
########################################################################################################

locals {
  resource_name      = ""
  dns_name           = ""
  container_port     = ""
  cluster_name       = ""
  availability_zones = ""
  container_cpu      = ""
  container_memory   = ""
  desired_count      = ""
  min_capacity       = ""
  max_capacity       = ""
  health_check_path  = ""

  # CONFIGURAÇÕES DA CONTA
  vpc_id       = ""
  account_id   = ""
  account_name = ""

  # CONFIGURAÇÕES DO ALB EXISTENTE 
  load_balancer_arn  = ""

  default_tags = {
    Area     = ""
    Ambiente = ""
  }

  # VARIÁVEIS GLOBAIS [PADRONIZADAS] - OBS: NÃO SE FAZ NECESSÁRIO REALIZAR A TROCA DE NENHUMA VARIÁVEL DESTE BLOCO !!!
  domain_name                        = "edtech.com.br"
  region                             = "us-east-1"
  cloudwatch_retention               = "14"
  launch_type                        = "EC2"
  network_mode                       = "bridge"
  https_protocol                     = "HTTPS"
  target_type                        = "instance"
  alb_type                           = "application"
  healthy_threshold                  = "3"
  interval                           = "300"
  http_protocol                      = "HTTP"
  matcher                            = "200,301,302"
  image_tags                         = "latest"
  timeout                            = "60"
  http_port                          = "80"
  https_port                         = "443"
  unhealthy_threshold                = "2"
  load_balancer_port                 = "443"
  target_group_port                  = "80"
  ssl_policy                         = "ELBSecurityPolicy-TLS13-1-2-FIPS-2023-04"
  deployment_minimum_healthy_percent = "100"
  target_value                       = "90"
  cooldown_for_scale_in              = "300"
  cooldown_for_scale_out             = "300"
  priority_rule                      = "1"
  rule_type                          = "redirect"
  status_code                        = "HTTP_301"
  alb_internal                       = "true"
  scheduling_strategy                = "REPLICA"
  maximum_healthy_percent            = "100"

  # CONFIGURAÇÕES INGRESS RULE - SECURITY GROUP*/
  description         = "Proxy Interno - VPC HUB"
  from_port           = "0"
  to_port             = "65535"
  protocol            = "tcp"
  security_group_type = "ingress"
  tcp_protocol        = "tcp"
  cidr_blocks         = "10.107.40.0/22"
}
