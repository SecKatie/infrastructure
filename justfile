# Ansible Playbooks - Task Runner

# Get Kubernetes Dashboard admin token and copy to clipboard
dashboard-token:
    @kubectl get secret admin-user-token -n kubernetes-dashboard -o jsonpath='{.data.token}' | base64 -d | pbcopy
    @echo "Dashboard token copied to clipboard"

# OpenTofu/Terraform commands

# Initialize OpenTofu
tf-init:
    cd opentofu && tofu init

# Validate OpenTofu configuration
tf-validate:
    cd opentofu && tofu validate

# Format OpenTofu configuration files
tf-fmt:
    cd opentofu && tofu fmt

# Plan infrastructure changes
tf-plan:
    cd opentofu && tofu plan

# Apply infrastructure changes
tf-apply:
    cd opentofu && tofu apply

# Show current infrastructure state
tf-show:
    cd opentofu && tofu show

# Refresh infrastructure state
tf-refresh:
    cd opentofu && tofu refresh

# Destroy infrastructure (use with caution!)
tf-destroy:
    cd opentofu && tofu destroy

# Upgrade OpenTofu providers
tf-upgrade:
    cd opentofu && tofu init -upgrade
