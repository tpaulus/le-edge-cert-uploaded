#!/bin/bash

if [ -z ${CF_API_KEY+x} ]; then
  echo "CF API Key is not set. Please set your Cloudflare API Key as the value of CF_API_KEY";
  exit 1;
fi

if [ -z ${CF_ZONE_ID+x} ]; then
  echo "CF_ZONE_ID is not set. Please set your Cloudflare Zone ID as CF_ZONE_ID";
  exit 1;
fi

if [ -z ${DOMAINS+x} ]; then
  echo "DOMAINS list is not set. Please set your list of domains to DOMAINS";
  exit 1;
fi

if [ -z ${EMAIL+x} ]; then
  echo "EMAIL is not set. Please set your email address as EMAIL";
  exit 1;
fi


cat > cloudflare_credentials.ini <<EOF
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = ${CF_API_KEY}
EOF

chmod 600 cloudflare_credentials.ini

certbot certonly \
  --key-type ecdsa \
  --dns-cloudflare \
  --dns-cloudflare-credentials cloudflare_credentials.ini \
  -m ${EMAIL} \
  --agree-tos \
  --non-interactive \
  -d ${DOMAINS}

cert_path=`ls -d /etc/letsencrypt/live/*/ | head -n 1`


id=`curl --get "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/custom_certificates" \
     -H "Authorization: Bearer ${CF_API_KEY}" | jq -r .result[0].id`

if [ "$id" != "null" ]; then
  # Update the existing cert
  echo "Updating Custom Certificate with ID: $id"
  curl -X PATCH "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/custom_certificates/${id}" \
       -H "Content-Type:application/json" \
       -H "Authorization: Bearer ${CF_API_KEY}" \
       --data "{\"certificate\": \"$(awk -v ORS='\\n' '1' ${cert_path}fullchain.pem)\", \"private_key\": \"$(awk -v ORS='\\n' '1' ${cert_path}privkey.pem)\", \"bundle_method\": \"force\"}" | jq .
else
  # Create a new Cert
  echo "Creating a new Custom Certificate"
  curl "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/custom_certificates" \
       -H "Content-Type:application/json" \
       -H "Authorization: Bearer ${CF_API_KEY}" \
       --data "{\"certificate\": \"$(awk -v ORS='\\n' '1' ${cert_path}fullchain.pem)\", \"private_key\": \"$(awk -v ORS='\\n' '1' ${cert_path}privkey.pem)\", \"type\": \"sni_custom\", \"bundle_method\": \"force\"}" | jq .
fi
