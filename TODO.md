- Sharkey role has directory permissions change, check later

TASK [sharkey : Ensure files directory exists with correct permissions] ************************************************
changed: [sharkey]

- Add restarting container stack for observability when configs changed

TASK [navidrome : Add NAS share to fstab for backups (noauto)] *********************************************************
[WARNING]: Ignore the 'boot' due to 'opts' contains 'noauto'.
ok: [navidrome]

- Unifi Controller role has directory permissions change, check later

TASK [unificontroller : Ensure UniFi data directory exists with correct permissions] ***********************************
changed: [unificontroller]

- Add a task/role to update all docker compose stacks?

- fix Forgejo this:
TASK [forgejo : Display backup discovery results] ****************************************************************************************************************************************************************************************
skipping: [forgejo]

TASK [forgejo : Create Forgejo directories] **********************************************************************************************************************************************************************************************
[WARNING]: The loop variable 'item' is already in use.
Origin: <unknown>

item

You should set the `loop_var` value in the `loop_control` option for the task to something else to avoid variable collisions and unexpected behavior.

TASK [forgejo : Add NAS mount to fstab] **************************************************************************************************************************************************************************************************
[WARNING]: Ignore the 'boot' due to 'opts' contains 'noauto'.
[WARNING]: Deprecation warnings can be disabled by setting `deprecation_warnings=False` in ansible.cfg.
[DEPRECATION WARNING]: Passing `warnings` to `exit_json` or `fail_json` is deprecated. This feature will be removed from ansible-core version 2.23. Use `AnsibleModule.warn` instead.
ok: [forgejo]

- change service ports to forward only to nginx gateway
- change exporter ports to forward only to prometheus 
- ^ do these so if it finds that a port is already open but not set to the correct destination then change it

- figure out how to have a proper staging env

- local nginx proxy for local services maybe?

- unbound filter out clients so that only some clients can access internal domains