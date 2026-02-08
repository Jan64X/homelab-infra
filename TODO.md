- Add restarting container stack for observability when configs changed

TASK [navidrome : Add NAS share to fstab for backups (noauto)] *********************************************************
[WARNING]: Ignore the 'boot' due to 'opts' contains 'noauto'.
ok: [navidrome]

- Unifi Controller role has directory permissions change, check later

TASK [unificontroller : Ensure UniFi data directory exists with correct permissions] ***********************************
changed: [unificontroller]

- Add a task/role to update all docker compose stacks?

- change exporter ports to forward only to prometheus 
- ^ do these so if it finds that a port is already open but not set to the correct destination then change it

- figure out how to have a proper staging env

- local nginx proxy for local services maybe?

- unbound filter out clients so that only some clients can access internal domains

- re-add forgejo but this time for local use