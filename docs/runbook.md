# ClowCodex Runbook

## What this deployment is

- OpenClaw gateway running as `clowcodex-openclaw.service`
- Telegram DM entrypoint using long polling
- Default agent runtime is ACP with the `codex` harness
- Server remains local-first: gateway binds to `127.0.0.1:18789`

## First deployment

1. Fill `.env` from `.env.example`.
2. Push the repository.
3. Run:

```bash
./scripts/deploy-remote.sh
```

## Pair your Telegram account

1. Open your bot in Telegram and send any DM.
2. On the server, list pending codes:

```bash
sudo -u clowcodex -H openclaw pairing list telegram
```

3. Approve the code:

```bash
sudo -u clowcodex -H openclaw pairing approve telegram <CODE>
```

After approval, direct messages from that Telegram account are accepted.

## How the bot behaves

- The default OpenClaw agent is configured with `runtime.type = "acp"`.
- That ACP runtime targets the `codex` harness with persistent mode.
- Result: direct messages go into a Codex-backed workspace without manually spawning `/acp`.

For future group/topic work you can still use explicit ACP commands like:

```text
/acp spawn codex --bind here
```

## Update flow

```bash
git pull --ff-only
sudo bash scripts/update-openclaw.sh
sudo bash scripts/smoke-test.sh
```

## Recovery

- Service status:

```bash
systemctl status clowcodex-openclaw --no-pager
```

- Recent logs:

```bash
journalctl -u clowcodex-openclaw -n 200 --no-pager
```

- Validate Telegram token:

```bash
source /etc/clowcodex/clowcodex.env
curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq .
```

- Validate Codex auth for the service user:

```bash
sudo -u clowcodex -H codex login status
```

## Secrets and state

Never commit:

- `/etc/clowcodex/clowcodex.env`
- `/home/clowcodex/.codex/auth.json`
- `/home/clowcodex/.openclaw/`
- pairing state
- logs or journal exports
