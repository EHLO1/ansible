# ansible-homelab

A pinned Ansible control node, with playbooks baked in, for managing homelab VMs.

The image is built from a fixed `ansible-core` + locked collections, so a given
commit produces a reproducible artifact. During development you overlay your
working tree so edits don't require a rebuild.

## Layout

```
Dockerfile          pinned control-node image
compose.yaml        ergonomic run-wrapper (ephemeral, not a service)
requirements.txt    pinned ansible-core
requirements.yml    Galaxy collections (none needed for today's playbooks)
ansible.cfg         defaults: inventory path, host key checking, pipelining
inventory/          static inventory + group_vars
playbooks/          site.yml (everything), update.yml, docker.yml
roles/
  baseline/         OS package updates + reboot-if-required (apt)
  docker/           Docker Engine install + permissions (official docs method)
```

## Prerequisites on each target VM

- An `ansible` login user that can `sudo` (NOPASSWD, or use `--ask-become-pass`).
- Your SSH public key in that user's `~/.ssh/authorized_keys`.
- Python 3 present (stock on Ubuntu Server).

## First run

```bash
# 1. Put your real hosts in inventory/hosts.yml.

# 2. Trust the hosts so host_key_checking can verify them:
ssh-keyscan -H 192.168.10.21 192.168.10.22 >> ~/.ssh/known_hosts

# 3. Load your key into an agent (keeps the key out of the container):
eval "$(ssh-agent)" && ssh-add ~/.ssh/your_key

# 4. Build and run:
docker compose build
docker compose run --rm ansible playbooks/site.yml
```

Target one host or one concern:

```bash
docker compose run --rm ansible playbooks/docker.yml --limit vm01
```

## Dev (live edits) vs frozen (baked-in)

`compose.yaml` bind-mounts `playbooks/`, `roles/`, and `inventory/` over the
copies baked into the image, so local edits take effect immediately. Comment
those three mounts out to run the frozen content the image was built with —
which is exactly what a CI-built, commit-tagged image runs.

## Secrets — never bake them in

Image layers are immutable and persist in history, so a key or vault password
baked in is effectively published. Keep them at runtime:

- **SSH keys:** forwarded via the agent socket (configured in `compose.yaml`).
- **Vault password:** mount a file and point `ANSIBLE_VAULT_PASSWORD_FILE` at it.
- Encrypt sensitive host/group vars with `ansible-vault`.

## Operational notes

- **Docker repo lag on brand-new releases.** The docker role derives the apt
  suite from the host's release codename (e.g. `resolute` for 26.04). If Docker
  hasn't published packages for a just-released Ubuntu yet, override per host or
  group: set `docker_apt_suite: noble`.
- **`docker` group is root-equivalent.** Membership lets a user mount the host
  FS into a container. `docker_users` defaults to your login user only.
- **Fedora later.** Ansible abstracts *a lot*, but package management and repo
  setup are exactly where the distro leaks through — apt vs dnf, and different
  Docker repo URLs. The clean pattern is a separate `fedora` inventory group and
  branching the baseline/docker task files on `ansible_os_family`. The update
  task here is apt-specific by design.

## Pinning collections

Today's playbooks use only `ansible.builtin`, so no collection is required.
When you add `community.general` (or others), install once and pin the resolved
version in `requirements.yml`:

```bash
docker compose run --rm --entrypoint ansible-galaxy ansible collection list
```
