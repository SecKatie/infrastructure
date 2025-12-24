resource "cloudflare_zone" "mulliken_net" {
  account = {
    id = "751a9e04a3fd32e066040d6bf45d1d47"
  }
  name = "mulliken.net"
  type = "full"
}

resource "cloudflare_dns_record" "a_gemini" {
  content = "136.57.83.9"
  name    = "gemini"
  proxied = false
  ttl     = 1
  type    = "A"
  zone_id = cloudflare_zone.mulliken_net.id
}

resource "cloudflare_dns_record" "a_proxy" {
  content = "136.57.83.9"
  name    = "proxy"
  proxied = false
  ttl     = 1
  type    = "A"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "a_status" {
  content = "66.63.163.116"
  name    = "status"
  proxied = true
  ttl     = 1
  type    = "A"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_acme_challenge_home" {
  comment = "Home Assistant Web (Nabu Casa)"
  content = "_acme-challenge.65b1ny6hduhu0gpsrxp5c29gjnpa2305.ui.nabu.casa"
  name    = "_acme-challenge.home"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_acme_challenge_links" {
  content = "links.mulliken.net.np10w0.flydns.net"
  name    = "_acme-challenge.links"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_fm1" {
  content = "fm1.mulliken.net.dkim.fmhosted.com"
  name    = "fm1._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_fm2" {
  content = "fm2.mulliken.net.dkim.fmhosted.com"
  name    = "fm2._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_fm3" {
  content = "fm3.mulliken.net.dkim.fmhosted.com"
  name    = "fm3._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_home" {
  comment = "Home Assistant Web (Nabu Casa)"
  content = "65b1ny6hduhu0gpsrxp5c29gjnpa2305.ui.nabu.casa"
  name    = "home"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_jellyfin" {
  content = "6c709ddf-a098-47a2-9995-d05c512b486d.cfargotunnel.com"
  name    = "jellyfin"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_jellyseerr" {
  comment = "Jellyseerr (Cloudflare Tunnel)"
  content = "dec97ed4-ca0a-4a28-8206-2cba39ad81e0.cfargotunnel.com"
  name    = "jellyseerr"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_links" {
  content = "my-link-blog.fly.dev"
  name    = "links"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_mta_sts_underscore" {
  content = "mta-sts.tutanota.de"
  name    = "_mta-sts"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_mta_sts" {
  content = "mta-sts.tutanota.de"
  name    = "mta-sts"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_apex" {
  content = "00450a34-9cc0-4c4d-9e6b-a4578c66acd0.cfargotunnel.com"
  name    = "mulliken.net"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_openpgpkey" {
  content = "wkd.keys.openpgp.org"
  name    = "openpgpkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_owntracks" {
  content = "2830b5f4-6830-41ee-9ed5-450a1ebec991.cfargotunnel.com"
  name    = "owntracks"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_paperless" {
  content = "7b0a2b09-96f0-412e-b222-c28f715356e1.cfargotunnel.com"
  name    = "paperless"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_protonmail2" {
  content = "protonmail2.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  name    = "protonmail2._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_protonmail3" {
  content = "protonmail3.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  name    = "protonmail3._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_protonmail" {
  content = "protonmail.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  name    = "protonmail._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_s1" {
  content = "s1.domainkey.tutanota.de"
  name    = "s1._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_dkim_s2" {
  content = "s2.domainkey.tutanota.de"
  name    = "s2._domainkey"
  proxied = false
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_tools" {
  content = "seckatie.github.io"
  name    = "tools"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "cname_umami" {
  content = "8a278e71-2282-4dd4-8f9c-10afd38740d8.cfargotunnel.com"
  name    = "umami"
  proxied = true
  ttl     = 1
  type    = "CNAME"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "mx_apex" {
  content  = "mail.tutanota.de"
  name     = "mulliken.net"
  priority = 10
  proxied  = false
  ttl      = 1
  type     = "MX"
  zone_id  = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_dmarc" {
  content = "\"v=DMARC1; p=quarantine; adkim=s\""
  name    = "_dmarc"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_dkim_krs" {
  content = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCzLd1TVdWvQIKqQcalekWGBq7AYwS1E9T/PTW2RxDRMO6D35EQVymrLNbiL03Ny8zM8BFSZB4K595XnI/hc0psTGsetjq3mUzP5ikSg7wZTSr/CxGcRL1W/dFDOoLTjGms2k7tDxlJDja2TfaW4uH9wVvhvS53gPgVJWpw3t8w6wIDAQAB"
  name    = "krs._domainkey"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_spf" {
  content = "\"v=spf1 include:spf.tutanota.de -all\""
  name    = "mulliken.net"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_tutanota_verify" {
  comment = "Tutanota"
  content = "\"t-verify=7a47f8578a6896d111a38bb4a38a33d9\""
  name    = "mulliken.net"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_keyoxide" {
  content = "aspe:keyoxide.org:ZBLFRTNC4BO7DN674KOCI62DNU"
  name    = "mulliken.net"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

resource "cloudflare_dns_record" "txt_protonmail_verify" {
  content = "protonmail-verification=6291766c6f5111eb61ab8a1568be003b452a62e9"
  name    = "mulliken.net"
  proxied = false
  ttl     = 1
  type    = "TXT"
  zone_id = "d582f580d9be2bc746c9e26410228219"
}

