# MinIO Configuration for Restic Backups (Append-Only)

This guide covers setting up MinIO S3-compatible storage for Restic backups with an append-only policy. This setup creates buckets and users that can write backups and manage locks, but cannot delete old backup data.

## Supported Services

This configuration works for the following services:
- **Forgejo** - Git hosting platform
- **Sharkey** - Fediverse social media server
- **GitLab** - DevOps platform with CI/CD
- **UniFi Controller** - Network management platform
- **Navidrome** - Music streaming server
- **Observability** - Prometheus and Grafana monitoring stack

All services use the same append-only pattern but with separate buckets and credentials for isolation.

## Setup Instructions

### 1. Connect to MinIO

(Skip if already configured)

```bash
mc alias set myminio http://<NAS_IP>:9000 root_user root_password
```

### 2. Create the Buckets

Create separate buckets for each service:

```bash
mc mb myminio/forgejo-backups
mc mb myminio/sharkey-backups
mc mb myminio/gitlab-backups
mc mb myminio/unifi-backups
mc mb myminio/navidrome-backups
mc mb myminio/observability-backups
```

### 3. Apply the Service-Specific Policies

Each service has its own append-only policy file in this directory that restricts DeleteObject to the locks/ directory only:
- `forgejo-restic-policy.json`
- `sharkey-restic-policy.json`
- `gitlab-restic-policy.json`
- `unificontroller-restic-policy.json`
- `navidrome-restic-policy.json`
- `observability-restic-policy.json`

Apply each policy to MinIO:

```bash
mc admin policy create myminio forgejo-restic-policy forgejo-restic-policy.json
mc admin policy create myminio sharkey-restic-policy sharkey-restic-policy.json
mc admin policy create myminio gitlab-restic-policy gitlab-restic-policy.json
mc admin policy create myminio unificontroller-restic-policy unificontroller-restic-policy.json
mc admin policy create myminio navidrome-restic-policy navidrome-restic-policy.json
mc admin policy create myminio observability-restic-policy observability-restic-policy.json
```

### 4. Create the Service Users

Create separate users for each service and attach the appropriate policies.

#### Forgejo User

```bash
# TIP: The username acts as the Access Key, and the password acts as the Secret Key.
mc admin user add myminio forgejo-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio forgejo-restic-policy --user forgejo-user
```

#### Sharkey User

```bash
mc admin user add myminio sharkey-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio sharkey-restic-policy --user sharkey-user
```

#### GitLab User

```bash
mc admin user add myminio gitlab-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio gitlab-restic-policy --user gitlab-user
```

#### UniFi Controller User

```bash
mc admin user add myminio unifi-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio unificontroller-restic-policy --user unifi-user
```

#### Navidrome User

```bash
mc admin user add myminio navidrome-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio navidrome-restic-policy --user navidrome-user
```

#### Observability User (Prometheus + Grafana)

```bash
mc admin user add myminio observability-user <STRONG_RANDOM_PASSWORD>
mc admin policy attach myminio observability-restic-policy --user observability-user
```

### 5. Get Credentials for Ansible

For each service, you have two options for Ansible variables:

#### Option A: Use the User Credentials (Simplest)

**Forgejo:**
- Access Key: `forgejo-user`
- Secret Key: The `<STRONG_RANDOM_PASSWORD>` you set above

**Sharkey:**
- Access Key: `sharkey-user`
- Secret Key: The `<STRONG_RANDOM_PASSWORD>` you set above

**GitLab:**
- Access Key: `gitlab-user`
- Secret Key: The `<STRONG_RANDOM_PASSWORD>` you set above

**UniFi Controller:**
- Access Key: `unifi-user`
- Secret Key: The `<STRONG_RANDOM_PASSWORD>` you set above

**Navidrome:**
- Access Key: `navidrome-user`
- Secret Key: The `<STRONG_RANDOM_PASSWORD>` you set above

Update `group_vars/homelab.yml`:

```yaml
# MinIO/S3 Configuration
minio_endpoint: "https://nas.core.lan:9000"

# Forgejo backup credentials
minio_forgejo_bucket: "forgejo-backups"
minio_forgejo_access_key: "forgejo-user"
minio_forgejo_secret_key: "your-forgejo-password-here"

# Sharkey backup credentials
minio_sharkey_bucket: "sharkey-backups"
minio_sharkey_access_key: "sharkey-user"
minio_sharkey_secret_key: "your-sharkey-password-here"

# GitLab backup credentials
minio_gitlab_bucket: "gitlab-backups"
minio_gitlab_access_key: "gitlab-user"
minio_gitlab_secret_key: "your-gitlab-password-here"
```

#### Option B: Generate Dedicated Service Accounts (Best Practice)

This creates random credential pairs tied to each user so you don't expose the main passwords.

**For Forgejo:**
```bash
mc admin user svcacct add myminio forgejo-user
```

**For Sharkey:**
```bash
mc admin user svcacct add myminio sharkey-user
```

**For GitLab:**
```bash
mc admin user svcacct add myminio gitlab-user
```

Output will look like:

```
Access Key: 39843248723...
Secret Key: 23847289347...
```

Use these values in your Ansible `group_vars/homelab.yml`.

### 6. Maintenance (The "Janitor")

Since the VMs cannot delete old data (append-only policy), you must run pruning from a secure admin machine (e.g., TrueNAS Cron or Admin PC) periodically (e.g., weekly).

#### Forgejo Maintenance

```bash
export AWS_ACCESS_KEY_ID="root_user"
export AWS_SECRET_ACCESS_KEY="root_password"
export RESTIC_REPOSITORY="s3:http://<NAS_IP>:9000/forgejo-backups"
export RESTIC_PASSWORD="<FORGEJO_RESTIC_REPO_PASSWORD>"

# This cleans up snapshots older than X days and removes the actual S3 objects
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

#### Sharkey Maintenance

```bash
export AWS_ACCESS_KEY_ID="root_user"
export AWS_SECRET_ACCESS_KEY="root_password"
export RESTIC_REPOSITORY="s3:http://<NAS_IP>:9000/sharkey-backups"
export RESTIC_PASSWORD="<SHARKEY_RESTIC_REPO_PASSWORD>"

# This cleans up snapshots older than X days and removes the actual S3 objects
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

#### GitLab Maintenance

```bash
export AWS_ACCESS_KEY_ID="root_user"
export AWS_SECRET_ACCESS_KEY="root_password"
export RESTIC_REPOSITORY="s3:http://<NAS_IP>:9000/gitlab-backups"
export RESTIC_PASSWORD="<GITLAB_RESTIC_REPO_PASSWORD>"

# This cleans up snapshots older than X days and removes the actual S3 objects
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
```

## Security Notes

1. **Append-Only Protection**: The policies restrict deletion to only the `locks/` directory, preventing VMs from deleting backup data even if compromised.

2. **Credential Isolation**: Each service has its own bucket and credentials, limiting the blast radius if credentials are compromised.

3. **Restic Passwords**: The Restic repository password (used for encryption) is separate from the S3 credentials and is auto-generated by Ansible in `credentials/hosts/<hostname>/restic_<service>_password.txt`.

4. **Admin Pruning**: Only admin credentials can delete old snapshots, which should be run from a trusted machine.

## Troubleshooting

### Connection Issues

Test connectivity from the VM:

```bash
# Source the restic environment (on the managed host)
source /opt/forgejo/restic-env.sh  # or /opt/sharkey/restic-env.sh or /opt/gitlab/restic-env.sh
restic snapshots
```

### Permission Denied

If you see "Access Denied" errors:
- Verify the policy is attached to the user
- Check bucket names match in policy and environment variables
- Ensure the MinIO endpoint is accessible from the VM

### Repository Not Found

```bash
# Initialize the repository (should happen automatically via Ansible)
source /opt/forgejo/restic-env.sh  # or appropriate service path
restic init --insecure-tls
```
