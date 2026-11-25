#!/bin/sh
# Runs a single-node Garage on the /data volume and, on first boot, creates the
# cluster layout, a bucket and an access key.
#   PORT               S3 API port (default 3900)
#   GARAGE_BUCKET      bucket to create (default my-bucket)
#   GARAGE_KEY_NAME    name of the access key (default admin-key)
#   GARAGE_ACCESS_KEY / GARAGE_SECRET_KEY  optional: import this key instead of generating one
set -eu

DATA=/data
PORT="${PORT:-3900}"
BUCKET="${GARAGE_BUCKET:-my-bucket}"
KEY_NAME="${GARAGE_KEY_NAME:-admin-key}"
CONF=/etc/garage.toml
mkdir -p "$DATA/meta" "$DATA/blocks"

# Secrets are created once and kept on the volume.
[ -s "$DATA/.rpc_secret" ] || openssl rand -hex 32 > "$DATA/.rpc_secret"
[ -s "$DATA/.admin_token" ] || openssl rand -hex 32 > "$DATA/.admin_token"

cat > "$CONF" <<EOF
metadata_dir = "$DATA/meta"
data_dir = "$DATA/blocks"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "$(cat "$DATA/.rpc_secret")"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:$PORT"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "$(cat "$DATA/.admin_token")"
EOF

g() { garage -c "$CONF" "$@"; }

g server &
SERVER=$!
trap 'kill $SERVER 2>/dev/null' INT TERM

i=0
until g status >/dev/null 2>&1; do
    i=$((i + 1))
    if [ "$i" -gt 60 ]; then echo "[garage] server did not start" >&2; exit 1; fi
    sleep 1
done

if [ ! -f "$DATA/.initialised" ]; then
    echo "[garage] first boot: creating layout, bucket and key"
    node=$(g node id -q 2>/dev/null | cut -d@ -f1)
    g layout assign -z railway -c 1G "$node"
    g layout apply --version 1
    g bucket create "$BUCKET" || true
    if [ -n "${GARAGE_ACCESS_KEY:-}" ] && [ -n "${GARAGE_SECRET_KEY:-}" ]; then
        g key import --yes -n "$KEY_NAME" "$GARAGE_ACCESS_KEY" "$GARAGE_SECRET_KEY"
    else
        g key create "$KEY_NAME"
    fi
    g bucket allow --read --write --owner "$BUCKET" --key "$KEY_NAME"
    touch "$DATA/.initialised"
    echo "[garage] ready. Show the key's secret with: garage key info --show-secret $KEY_NAME"
fi

wait $SERVER
