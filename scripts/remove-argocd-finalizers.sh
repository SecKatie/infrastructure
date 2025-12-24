#!/bin/bash
# Remove finalizers from all ArgoCD Application resources
# Useful when applications are stuck in deletion

set -euo pipefail

NAMESPACE="argocd"

echo "Fetching all ArgoCD Applications in $NAMESPACE..."

kubectl get applications.argoproj.io -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read -r name; do
    [[ -z "$name" ]] && continue

    echo "Removing finalizers from $NAMESPACE/$name..."
    kubectl patch application "$name" -n "$NAMESPACE" --type=merge -p '{"metadata":{"finalizers":null}}'
done

echo "Done."
