## Authenticating Claude Code

Claude Code requires a **Pro, Max, Team, or Enterprise** Claude.ai subscription, or a **Claude Console** API key. The free Claude.ai plan does not include Claude Code access.

### First launch — browser login (recommended for personal use)

Open a terminal inside the container and run:

```bash
claude
```

Claude Code opens a browser window for you to sign in with your Claude.ai account. Inside a container the browser redirect may not complete automatically — if that happens, press `c` to copy the login URL, paste it into your host browser, and then paste the confirmation code back into the terminal when prompted.

Your credentials are stored in `~/.claude/` inside the container. This devcontainer mounts that directory as a named Docker volume (`claude-code-config-<id>`), so **you only need to log in once per container instance** — credentials survive container restarts and rebuilds.

> Official docs: [Authentication — Claude Code](https://code.claude.com/docs/en/authentication)

---

### API key (Console accounts / CI)

If your organisation bills through the [Claude Console](https://console.anthropic.com) rather than a subscription, get an API key at **console.anthropic.com → API Keys**.

The recommended way to persist the key is in **VS Code user settings**. It is then available in every VS Code terminal — including devcontainer terminals — without any per-session export:

```jsonc
// Open with: Ctrl+Shift+P → "Preferences: Open User Settings (JSON)"
{
  "terminal.integrated.env.linux": {
    "ANTHROPIC_API_KEY": "sk-ant-..."
  }
}
```

Use `terminal.integrated.env.osx` on macOS or `terminal.integrated.env.windows` on Windows.

The devcontainer also picks up `ANTHROPIC_API_KEY` from your host shell environment via `remoteEnv`, so setting it in your shell profile (`~/.bashrc` / `~/.zshrc`) works as a fallback if you prefer that approach.

In interactive mode Claude Code prompts you once to approve the key; your choice is remembered. To change it later use the **"Use custom API key"** toggle in `/config`.

> Get a key at [console.anthropic.com](https://console.anthropic.com) → API Keys.

---

### Long-lived token (headless / CI pipelines)

For environments where browser login is not possible — GitHub Actions, scripts, SSH-only sessions — generate a one-year OAuth token:

```bash
claude setup-token
```

Copy the printed token and add it to your **VS Code user settings** so it is available in all devcontainer terminals automatically:

```jsonc
// Open with: Ctrl+Shift+P → "Preferences: Open User Settings (JSON)"
{
  "terminal.integrated.env.linux": {
    "CLAUDE_CODE_OAUTH_TOKEN": "<token>"
  }
}
```

Or set it in your host shell profile as a fallback:

```bash
export CLAUDE_CODE_OAUTH_TOKEN=<token>
```

This token authenticates against your subscription (Pro, Max, Team, or Enterprise) and is scoped to inference only.

> See [Generate a long-lived token](https://code.claude.com/docs/en/authentication#generate-a-long-lived-token) in the official docs.

---

### Authentication precedence

When multiple credentials are present Claude Code picks in this order:

| Priority | Method |
|---|---|
| 1 | Cloud provider env vars (`CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`) |
| 2 | `ANTHROPIC_AUTH_TOKEN` (bearer token for LLM gateways / proxies) |
| 3 | `ANTHROPIC_API_KEY` (Console API key) |
| 4 | `apiKeyHelper` script (dynamic / rotating credentials) |
| 5 | `CLAUDE_CODE_OAUTH_TOKEN` (long-lived token from `claude setup-token`) |
| 6 | Subscription OAuth from `/login` (default for personal accounts) |

> Full reference: [Authentication — Claude Code](https://code.claude.com/docs/en/authentication#authentication-precedence)

---

### Logging out

To log out and re-authenticate, type `/logout` at the Claude Code prompt.
