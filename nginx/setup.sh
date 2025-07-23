#!/bin/bash
set -e

# PDS nginx setup script
# Usage: ./setup.sh your.domain.com

if [ $# -ne 1 ]; then
    echo "Usage: $0 <hostname>"
    echo "Example: $0 pds.example.com"
    exit 1
fi

HOSTNAME="$1"
NGINX_DIR="$(dirname "$0")"
CONFIG_FILE="$NGINX_DIR/pds.conf"

# Create a configured version of the nginx config
sed "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" "$CONFIG_FILE" > "$NGINX_DIR/pds-configured.conf"

echo "Generated configured nginx file: $NGINX_DIR/pds-configured.conf"
echo ""
echo "Next steps:"
echo "1. Ensure your SSL certificates exist at: /etc/letsencrypt/live/$HOSTNAME/"
echo "2. Update compose.yaml if needed"
echo "3. Run: docker compose up -d"
echo ""
echo "SSL certificate commands (run on host):"
echo "  sudo certbot certonly --webroot -w /var/www/certbot -d $HOSTNAME -d *.$HOSTNAME"