#!/usr/bin/env bash
#
DOMAIN='example.org'
EMAIL=your@email.example.org
LETSENCRYPT_DIR="./letsencrypt"

    # Ensure directories exist or create them
if [ ! -d "$LETSENCRYPT_DIR" ]; then
    mkdir -p "$LETSENCRYPT_DIR" || { echo "Erro ao criar diretório: $LETSENCRYPT_DIR"; exit 1; }
fi

docker run --rm -p 80:80 \
  -v "./letsencrypt/certbot/conf:/etc/letsencrypt" \
  -v "./letsencrypt/certbot/www:/var/www/certbot" \
  certbot/certbot certonly --standalone \
  -d "$DOMAIN" --agree-tos -n -m "$EMAIL"

