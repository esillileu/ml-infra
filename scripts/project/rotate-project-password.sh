#!/usr/bin/env bash
set -euo pipefail

name="${1:?usage: $0 <name>}"

if [[ ! "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "invalid name: $name" >&2
    exit 1
fi

secret="${name}_pgpass"
service="${name}.service"

read -rsp "New password: " password
echo
read -rsp "Confirm password: " password2
echo

if [[ "$password" != "$password2" ]]; then
    echo "passwords do not match" >&2
    exit 1
fi

unset password2

printf 'ALTER ROLE "%s" PASSWORD '\''%s'\'';\n' \
    "$name" "$password" |
    podman exec -i postgres \
        psql -v ON_ERROR_STOP=1 -U postgres -d postgres

printf 'postgres:5432:%s:%s:%s' \
    "$name" "$name" "$password" |
    podman secret create --replace "$secret" -

unset password

if systemctl --user cat "$service" >/dev/null 2>&1; then
    systemctl --user restart "$service"
fi

echo "credential rotated: $name"