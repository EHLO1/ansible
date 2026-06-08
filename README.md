# Examples

### Default
```yaml
command: ["site.yml"]
```
Translates to: `ansible-playbook -i proxmox.yml site.yml`


### Host List Override
```yaml
command: ["-i", "192.168.1.150,", "site.yml"]
```
Translates to: `ansible-playbook -i 192.168.1.150, site.yml`

### Inventory File Override
```yaml
command: ["-i", "local-docker-nodes.yml", "site.yml"]
```
Translates to: `ansible-playbook -i local-docker-nodes.yml site.yml`

# Requirements

Save BWS_ACCESS_TOKEN to a file and secure it
```shell
sudo mkdir -p /opt/secrets && \
echo "your-bws-access-token" | sudo tee /opt/secrets/bws_access_token && \
sudo chmod 600 /opt/secrets/bws_access_token
```

Mount it as a Docker Secret
```yaml
secrets:
  bws_access_token:
    file: /opt/secrets/bws_access_token
```

Either create additional secrets in the same way as bws_access_token or include the Bitwarden Secrets Manager UUIDs as environment variables.