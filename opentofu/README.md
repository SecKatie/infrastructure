# OpenTofu Infrastructure Management

This directory contains OpenTofu (open-source Terraform) configuration for managing infrastructure as code, specifically Cloudflare DNS for mulliken.net.

## Prerequisites

### Install OpenTofu

OpenTofu is an open-source fork of Terraform. Install it using Homebrew:

```bash
brew install opentofu
```

Or using the official installer:
```bash
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh
```

### Get Cloudflare Credentials

You'll need:
1. **API Token**: Create a token at https://dash.cloudflare.com/profile/api-tokens
   - Use the "Edit zone DNS" template
   - Grant permissions for the mulliken.net zone
2. **Account ID**: Found in your Cloudflare dashboard URL
3. **Zone ID**: Found in the overview section of your mulliken.net domain

## Initial Setup

1. **Create your variables file:**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your actual values:**
   ```hcl
   cloudflare_account_id = "your-actual-account-id"
   cloudflare_zone_id    = "your-actual-zone-id"
   domain                = "mulliken.net"
   ```

3. **Set your API token as an environment variable:**
   ```bash
   export CLOUDFLARE_API_TOKEN="your-api-token-here"
   ```
   
   Consider adding this to your shell profile (~/.zshrc or ~/.bashrc) or use a secrets manager.

4. **Initialize OpenTofu:**
   ```bash
   tofu init
   ```

## Usage

### Plan Changes

Preview what changes will be made:
```bash
tofu plan
```

### Apply Changes

Apply the configuration:
```bash
tofu apply
```

### Show Current State

View the current infrastructure state:
```bash
tofu show
```

### Import Existing Resources

If you have existing DNS records in Cloudflare that you want to manage with OpenTofu, you can import them:

```bash
# Import a DNS record (you'll need the record ID from Cloudflare)
tofu import cloudflare_record.example <zone_id>/<record_id>
```

To get record IDs, you can use the Cloudflare API or dashboard.

### Validate Configuration

Check if your configuration is valid:
```bash
tofu validate
```

### Format Code

Format your .tf files:
```bash
tofu fmt
```

## Configuration Files

- `versions.tf` - OpenTofu and provider version requirements
- `provider.tf` - Cloudflare provider configuration
- `variables.tf` - Variable definitions
- `dns.tf` - DNS record configurations
- `terraform.tfvars` - Variable values (gitignored, create from example)

## Managing DNS Records

### Adding New Records

Edit `dns.tf` and add new resources. Examples:

**A Record:**
```hcl
resource "cloudflare_record" "example" {
  zone_id = var.cloudflare_zone_id
  name    = "subdomain"
  content = "1.2.3.4"
  type    = "A"
  ttl     = 1  # Auto TTL
  proxied = true
}
```

**CNAME Record:**
```hcl
resource "cloudflare_record" "example" {
  zone_id = var.cloudflare_zone_id
  name    = "subdomain"
  content = "target.example.com"
  type    = "CNAME"
  ttl     = 1
  proxied = false
}
```

**TXT Record:**
```hcl
resource "cloudflare_record" "example" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = "v=spf1 include:_spf.example.com ~all"
  type    = "TXT"
  ttl     = 3600
  proxied = false
}
```

After adding records, run:
```bash
tofu plan   # Review changes
tofu apply  # Apply changes
```

## Best Practices

1. **Always run `tofu plan` before `tofu apply`**
2. **Keep your API token secure** - never commit it to version control
3. **Use version control** for your .tf files (but not .tfvars)
4. **Test changes in a plan before applying**
5. **Document your DNS records** with comments in the code
6. **Consider remote state** for team collaboration (e.g., S3, Terraform Cloud)

## Troubleshooting

### Authentication Issues

If you get authentication errors:
- Verify your API token is correctly set
- Check token permissions include DNS edit for the zone
- Ensure the token hasn't expired

### State Issues

If state becomes corrupted or out of sync:
```bash
tofu refresh  # Refresh state from actual infrastructure
```

### Provider Version Issues

Update providers to latest compatible versions:
```bash
tofu init -upgrade
```

## Migration from Terraform

OpenTofu is fully compatible with Terraform configurations. If you were using Terraform before:

1. Replace `terraform` commands with `tofu`
2. Existing .tfstate files work as-is
3. Provider syntax remains the same

## Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Cloudflare Provider Documentation](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)

