# clowcodex repo instructions

- This repository is infrastructure-first: shell scripts, systemd units, JSON/TOML templates, and runbooks.
- Prefer idempotent changes. Server install/update scripts must be safe to rerun.
- Never commit secrets, tokens, pairing codes, auth.json files, logs, or runtime state.
- Validate shell scripts with `bash -n` after edits.
- Keep OpenClaw config aligned with current upstream ACP and Telegram semantics.
- This deployment is Codex-first: the default agent runtime should be ACP with the `codex` harness.
- Preserve local-only gateway exposure unless a task explicitly adds a reverse proxy.

