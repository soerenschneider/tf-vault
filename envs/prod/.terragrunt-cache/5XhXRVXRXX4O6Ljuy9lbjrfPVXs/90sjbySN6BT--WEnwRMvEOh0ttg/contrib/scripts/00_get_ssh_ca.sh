#!/bin/sh

DEFAULT_HOST_SSH_MOUNT=ssh/servers
DEFAULT_CLIENT_SSH_MOUNT=ssh/clients

echo "server ca"
curl "${VAULT_ADDR}/v1/${DEFAULT_HOST_SSH_MOUNT}/public_key"

echo "client ca"
curl "${VAULT_ADDR}/v1/${DEFAULT_CLIENT_SSH_MOUNT}/public_key"
