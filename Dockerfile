# Bitwarden Secrets CLI
FROM ghcr.io/bitwarden/bws:latest AS bws_image

# Main Image
FROM python:3.14-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Dependencies
RUN apt-get update && apt-get install -y \
    jq \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# Install Ansible and Proxmox API dependencies
RUN pip install --no-cache-dir ansible proxmoxer requests

# Install Required Ansible Collection for Proxmox
RUN ansible-galaxy collection install community.general

# Copy the bws binary
COPY --from=bws_image /bin/bws /usr/local/bin/bws
RUN chmod +x /usr/local/bin/bws

COPY ./ansible-data /opt/ansible
WORKDIR /opt/ansible

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]