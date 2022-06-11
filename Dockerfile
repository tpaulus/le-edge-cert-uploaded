FROM ubuntu:kinetic

RUN apt-get update; \
    apt-get install python3 python3-venv libaugeas0 curl jq -y; \
    python3 -m venv /opt/certbot/; \
    /opt/certbot/bin/pip install --upgrade pip; \
    /opt/certbot/bin/pip install certbot; \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot; \
    /opt/certbot/bin/pip install certbot-dns-cloudflare;

COPY entrypoint.sh .

ENTRYPOINT []
CMD ["/bin/bash", "entrypoint.sh"]