#!/bin/sh

DEFAULT_PKI_URL=pki_root
DETECTED_PKI_URL=$(grep root_mount_path pki_internal_root_ca.tf | awk '{print $3}' | tr -d '"')

curl "${VAULT_ADDR}/v1/${DETECTED_PKI_URL:-$DEFAULT_PKI_URL}/ca/pem"
