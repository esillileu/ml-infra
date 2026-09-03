# MLflow reverse SSH tunnels

This directory is the source of truth for opt-in reverse tunnels from local
MLflow (`127.0.0.1:5001`) to a remote loopback listener
(`127.0.0.1:15001`). No instance is enabled, so tunnels start only after an
explicit `on` and do not start automatically after reboot.

## Deploy

```bash
cd /opt/infra
just mlflow-tunnel-deploy
chezmoi apply ~/.bashrc
loginctl enable-linger "$USER"
```

The recipe creates symlinks under `~/.local/bin`, `~/.config/systemd/user`,
and `~/.config/mlflow-tunnel`, then runs `systemctl --user daemon-reload`. It
refuses to overwrite an existing file or unexpected symlink. Lingering keeps
an explicitly started user service alive after logout; it does not enable the
unit or make it start after reboot.

## Configure targets

Add `targets/<name>.conf` containing only:

```text
HOST=server.example.com
USER=remote-user
SSH_PORT=22
```

`HOST` and `USER` are required; `SSH_PORT` is optional and defaults to 22.
Target names, values, duplicate keys, unknown keys, and port ranges are
validated without sourcing or evaluating the file. The initial target is
`super` (`user3@163.152.23.181:22`).

## Operate

```bash
mlflow-tunnel on super
mlflow-tunnel status super
mlflow-tunnel status
mlflow-tunnel off super
journalctl --user -u mlflow-tunnel@super.service
```

SSH public-key authentication must already work non-interactively (`ssh -o
BatchMode=yes user3@163.152.23.181 true`). The service uses keepalives,
requires forwarding setup to succeed, and reconnects five seconds after an
unexpected failure. `off` cancels that restart loop.

## Security checks

The remote forwarding request is exactly
`127.0.0.1:15001:127.0.0.1:5001`. Confirm the remote sshd has `GatewayPorts
no` (the default) or `clientspecified`; `GatewayPorts yes` may replace the
requested loopback bind with a wildcard listener.

After starting, verify on the remote host:

```bash
ss -ltn '( sport = :15001 )'
curl http://127.0.0.1:15001/
```

The listener must show only `127.0.0.1:15001` (and not `0.0.0.0` or `::`).
Also confirm a connection to port 15001 through the remote host's non-loopback
address fails. After `off`, the listener and HTTP access must disappear.
