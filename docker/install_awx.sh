#!/bin/bash

set -e

# Environment variables (injected or hardcoded as fallback)
AWX_DB_HOST=${AWX_DB_HOST:-"localhost"}
AWX_DB_NAME=${AWX_DB_NAME:-"awxdb"}
AWX_DB_USER=${AWX_DB_USER:-"awxuser"}
AWX_DB_PASSWORD=${AWX_DB_PASSWORD:-"changeme"}

# Create inventory file for installer
cat <<EOF > inventory
[all:vars]
postgres_data_dir="/tmp/pgdocker"
awx_official=true
admin_user=admin
admin_password=password
secret_key=$(openssl rand -hex 32)
pg_username=${AWX_DB_USER}
pg_password=${AWX_DB_PASSWORD}
pg_database=${AWX_DB_NAME}
pg_host=${AWX_DB_HOST}

[all]
localhost ansible_connection=local
EOF

# Run installer
ansible-playbook -i inventory install.yml
