########################################################################################################
#                                                                                                      #
#                   DECLARAÇÃO DE VALORES DA CONTA QUE SERÁ CRIADA O DNS (ROUTE 53)                    #
#                                                                                                      #
########################################################################################################

data "aws_route53_zone" "dns_zone" {
  provider     = aws.sua_conta
  name         = local.domain_name
  private_zone = "false"
}

resource "aws_route53_record" "main" {
  provider = aws.sua_conta

  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${local.dns_name}.${local.domain_name}"
  type    = "CNAME"
  ttl     = "60"
  records = [data.aws_lb.main.dns_name]
}