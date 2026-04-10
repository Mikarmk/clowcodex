# clowcodex

Infrastructure repo for a Telegram-first OpenClaw deployment that routes chats into Codex via ACP on a dedicated server.

## Layout

- `scripts/` bootstrap, install, update, deploy, smoke checks
- `config/` OpenClaw and Codex config templates
- `deploy/systemd/` systemd service template
- `docs/` operator runbooks

## Intended runtime

- Ubuntu server
- Node.js 24
- `openclaw@latest`
- `@openai/codex`
- Telegram long polling
- Closed-access DM policy by default

## Deploy flow

1. Fill `.env` from `.env.example`
2. Push repo to GitHub
3. Run `scripts/deploy-remote.sh`
4. Pair your Telegram account
5. Validate with `scripts/smoke-test.sh`

See [docs/runbook.md](/Users/murat/openCLIcodexclaw/repo/docs/runbook.md) for the full operator flow.

