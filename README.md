# bob2

## Codespaces Desktop (VNC in browser)

This repo is configured with the Desktop Lite devcontainer feature so you can run a lightweight Linux desktop inside GitHub Codespaces.

### One-time setup

1. Open this repo in a Codespace.
2. Rebuild the container:
	- Command Palette -> `Codespaces: Rebuild Container`

### One-command startup check

Run this in the Codespace terminal:

```bash
./scripts/codespace-desktop.sh start
```

This command checks whether noVNC is already listening on port `6080`, attempts to start desktop services if needed, and prints the expected desktop URL.

### Open the desktop

1. Open the **Ports** panel in Codespaces.
2. Find port `6080` labeled **Desktop (noVNC)**.
3. Keep visibility set to **Private**.
4. Open the forwarded port in browser.

You should see a Linux desktop in your browser tab. From there, launch Firefox or Chromium.

### Health checks and troubleshooting

If port `6080` does not appear or the page does not load, run:

```bash
./scripts/codespace-desktop.sh status
ss -ltn | grep ':6080' || true
echo "$CODESPACE_NAME"
echo "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
```

What to do based on results:

1. `status` says not listening:
	- Run `./scripts/codespace-desktop.sh start`.
	- If still down, rebuild container again.
2. Port is listening but browser fails:
	- In Ports panel, confirm port `6080` is **Private** and open its URL from the panel.
3. Codespace variables are empty:
	- Reopen the terminal and rerun, or open the port directly from the Ports panel.