locals {
  zone = "mulliken.net"
}

# =============================================================================
# Dynamic A Records (managed by DynDNS updater CronJob)
# =============================================================================

resource "dnsimple_zone_record" "a_wildcard" {
  zone_name = local.zone
  name      = "*"
  value     = "136.57.83.9"
  type      = "A"
  ttl       = 300

  lifecycle {
    ignore_changes = [value]
  }
}

resource "dnsimple_zone_record" "a_apex" {
  zone_name = local.zone
  name      = ""
  value     = "136.57.83.9"
  type      = "A"
  ttl       = 300

  lifecycle {
    ignore_changes = [value]
  }
}

# =============================================================================
# Static A Records
# =============================================================================

resource "dnsimple_zone_record" "a_gemini" {
  zone_name = local.zone
  name      = "gemini"
  value     = "136.57.83.9"
  type      = "A"
  ttl       = 3600
}

resource "dnsimple_zone_record" "a_proxy" {
  zone_name = local.zone
  name      = "proxy"
  value     = "136.57.83.9"
  type      = "A"
  ttl       = 3600
}

resource "dnsimple_zone_record" "a_status" {
  zone_name = local.zone
  name      = "status"
  value     = "66.63.163.116"
  type      = "A"
  ttl       = 3600
}

# =============================================================================
# MX Records — Mailbox.org
# =============================================================================

resource "dnsimple_zone_record" "mx_mailbox_mxext1" {
  zone_name = local.zone
  name      = ""
  value     = "mxext1.mailbox.org"
  type      = "MX"
  ttl       = 3600
  priority  = 10
}

resource "dnsimple_zone_record" "mx_mailbox_mxext2" {
  zone_name = local.zone
  name      = ""
  value     = "mxext2.mailbox.org"
  type      = "MX"
  ttl       = 3600
  priority  = 10
}

resource "dnsimple_zone_record" "mx_mailbox_mxext3" {
  zone_name = local.zone
  name      = ""
  value     = "mxext3.mailbox.org"
  type      = "MX"
  ttl       = 3600
  priority  = 20
}

# =============================================================================
# TXT Records
# =============================================================================

resource "dnsimple_zone_record" "txt_spf" {
  zone_name = local.zone
  name      = ""
  value     = "v=spf1 include:mailbox.org ~all"
  type      = "TXT"
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_dmarc" {
  zone_name = local.zone
  name      = "_dmarc"
  value     = "v=DMARC1; p=none; rua=mailto:postmaster@mulliken.net"
  type      = "TXT"
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_keyoxide" {
  zone_name = local.zone
  name      = ""
  value     = "aspe:keyoxide.org:ZBLFRTNC4BO7DN674KOCI62DNU"
  type      = "TXT"
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_protonmail_verify" {
  zone_name = local.zone
  name      = ""
  value     = "protonmail-verification=6291766c6f5111eb61ab8a1568be003b452a62e9"
  type      = "TXT"
  ttl       = 3600
}

resource "dnsimple_zone_record" "txt_dkim_krs" {
  zone_name = local.zone
  name      = "krs._domainkey"
  value     = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCzLd1TVdWvQIKqQcalekWGBq7AYwS1E9T/PTW2RxDRMO6D35EQVymrLNbiL03Ny8zM8BFSZB4K595XnI/hc0psTGsetjq3mUzP5ikSg7wZTSr/CxGcRL1W/dFDOoLTjGms2k7tDxlJDja2TfaW4uH9wVvhvS53gPgVJWpw3t8w6wIDAQAB"
  type      = "TXT"
  ttl       = 3600
}

# =============================================================================
# CNAME Records — Email DKIM (Mailbox.org)
# =============================================================================

resource "dnsimple_zone_record" "cname_dkim_mbo0001" {
  zone_name = local.zone
  name      = "mbo0001._domainkey"
  value     = "mbo0001._domainkey.mailbox.org"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_mbo0002" {
  zone_name = local.zone
  name      = "mbo0002._domainkey"
  value     = "mbo0002._domainkey.mailbox.org"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_mbo0003" {
  zone_name = local.zone
  name      = "mbo0003._domainkey"
  value     = "mbo0003._domainkey.mailbox.org"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_mbo0004" {
  zone_name = local.zone
  name      = "mbo0004._domainkey"
  value     = "mbo0004._domainkey.mailbox.org"
  type      = "CNAME"
  ttl       = 3600
}

# =============================================================================
# CNAME Records — Email DKIM (Fastmail / Protonmail — legacy, from Cloudflare)
# =============================================================================

resource "dnsimple_zone_record" "cname_dkim_fm1" {
  zone_name = local.zone
  name      = "fm1._domainkey"
  value     = "fm1.mulliken.net.dkim.fmhosted.com"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_fm2" {
  zone_name = local.zone
  name      = "fm2._domainkey"
  value     = "fm2.mulliken.net.dkim.fmhosted.com"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_fm3" {
  zone_name = local.zone
  name      = "fm3._domainkey"
  value     = "fm3.mulliken.net.dkim.fmhosted.com"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_protonmail" {
  zone_name = local.zone
  name      = "protonmail._domainkey"
  value     = "protonmail.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_protonmail2" {
  zone_name = local.zone
  name      = "protonmail2._domainkey"
  value     = "protonmail2.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_dkim_protonmail3" {
  zone_name = local.zone
  name      = "protonmail3._domainkey"
  value     = "protonmail3.domainkey.doqdlbrh5lwhunlleppnwksz6tomqano3as6iyomxrvdcjqi5qprq.domains.proton.ch"
  type      = "CNAME"
  ttl       = 3600
}

# =============================================================================
# CNAME Records — External Services
# =============================================================================

resource "dnsimple_zone_record" "cname_autoconfig" {
  zone_name = local.zone
  name      = "autoconfig"
  value     = "autoconfig.mailbox.org"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_home" {
  zone_name = local.zone
  name      = "home"
  value     = "65b1ny6hduhu0gpsrxp5c29gjnpa2305.ui.nabu.casa"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_acme_challenge_home" {
  zone_name = local.zone
  name      = "_acme-challenge.home"
  value     = "_acme-challenge.65b1ny6hduhu0gpsrxp5c29gjnpa2305.ui.nabu.casa"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_links" {
  zone_name = local.zone
  name      = "links"
  value     = "my-link-blog.fly.dev"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_acme_challenge_links" {
  zone_name = local.zone
  name      = "_acme-challenge.links"
  value     = "links.mulliken.net.np10w0.flydns.net"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_tools" {
  zone_name = local.zone
  name      = "tools"
  value     = "seckatie.github.io"
  type      = "CNAME"
  ttl       = 3600
}

resource "dnsimple_zone_record" "cname_openpgpkey" {
  zone_name = local.zone
  name      = "openpgpkey"
  value     = "wkd.keys.openpgp.org"
  type      = "CNAME"
  ttl       = 3600
}

# =============================================================================
# SRV Records — Mailbox.org autodiscovery
# =============================================================================

resource "dnsimple_zone_record" "srv_autodiscover" {
  zone_name = local.zone
  name      = "_autodiscover._tcp"
  value     = "0 443 auto.mailbox.org."
  type      = "SRV"
  ttl       = 3600
  priority  = 0
}

resource "dnsimple_zone_record" "srv_hkps" {
  zone_name = local.zone
  name      = "_hkps._tcp"
  value     = "1 443 pgp.mailbox.org."
  type      = "SRV"
  ttl       = 3600
  priority  = 1
}
