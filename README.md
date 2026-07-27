# Standard Dev Environment — Windows + WSL

## Structure

```
entorno-dev/
├── windows/
│   └── entorno.dsc.yaml      # Windows-side apps (VS Code, font, browsers)
├── wsl-nix/
│   ├── flake.nix               # Pins nixpkgs + home-manager
│   └── home.nix                # Full WSL toolchain, dotfiles, directory structure
└── README.md
```

## What gets installed

### Windows (`entorno.dsc.yaml`)

| Tool | Description |
|---|---|
| Visual Studio Code | Main editor |
| JetBrains Mono Nerd Font | Terminal font (Starship prompt + Zellij icons) |
| Brave | Primary browser |
| Google Chrome | Secondary browser (testing/QA) |

### WSL — Nix Home Manager (`home.nix`)

**Editors and terminal**
- `sublime4` — lightweight editor (`subl`, GUI via WSLg)
- `zellij` — terminal multiplexer

**Containers**
- `podman` + `podman-compose` — rootless Docker equivalent (runs directly in WSL2, no extra VM)

**Databases**
- `dbeaver-bin` — universal GUI client (via WSLg)
- `postgresql_16` — `psql` CLI client
- `pgcli` — interactive client with autocompletion and syntax highlighting

**Version managers**
- `mise` — Java and Node (defaults: Temurin 21 and Node 22; per-project override via `.mise.toml`)
- `uv` — Python (version and virtual environment management)

**Local AI and CLI tools**
- `ollama` — local language models
- `@anthropic-ai/claude-code` *(npm)* — Claude Code CLI
- `opencode-ai` *(npm)* — OpenCode CLI
- `@openai/codex` *(npm)* — Codex CLI

**Notes and documentation**
- `obsidian` — vault at `~/obsidian` (GUI via WSLg)

**Utilities**
- `ripgrep`, `fzf`, `fd` — fast search
- `jq` — JSON processing
- `httpie` — readable HTTP client (`http POST api.com/...`)
- `nmap` — network/port scanner
- `wget`, `unzip`, `coreutils`

**Shell and prompt**
- `fish` — default login shell (set automatically via `chsh` on first apply)
- `zsh` — also available as fallback
- `starship` — configurable prompt (integrated with fish)
- `atuin` — command history search (replaces Ctrl+R with a searchable, syncable history UI; integrated with fish)

**Directory structure created automatically**
```
~/projects/    # code
~/obsidian/    # Obsidian vault
~/downloads/
~/cloude/      # mount point for rclone (Google Drive, Dropbox, etc.)
```

---

## Applying on Windows

First install WSL (requires admin PowerShell; reboot if prompted):

```powershell
wsl --install
```

Then apply the rest of the environment:

```powershell
winget configure --file windows\entorno.dsc.yaml --accept-configuration-agreements
```

## Applying on WSL (Ubuntu)

1. Install Nix (if not already installed):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```
2. Restart WSL so the Nix daemon is available. Run this from PowerShell on Windows, then reopen your WSL terminal:
   ```powershell
   wsl --shutdown
   ```
3. Enable flakes (one time only):
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```
4. Clone this repo and apply:
   ```bash
   git clone https://github.com/djanr2/dev.environment.git ~/dev.environment
   cd ~/dev.environment/wsl-nix
   nix run home-manager/master -- switch --flake .#dev-environment
   ```

## Keeping packages up to date

Run this from `~/dev.environment/wsl-nix` to update all Nix inputs (nixpkgs, home-manager) to their latest versions:

```bash
nix flake update
```

Then re-apply to pick up the changes:

```bash
home-manager switch --flake .#dev-environment
```

## Important notes before applying as-is

- **Verify package names**: nixpkgs renames packages over time (e.g. `nerd-fonts.caskaydia-cove`, `dbeaver-bin`, `sublime4`). Before applying, run `nix search nixpkgs <package>` to confirm the exact name on your nixpkgs revision.
- **Claude Code, OpenCode, Codex CLI**: installed via npm in the activation step because they aren't stably packaged in nixpkgs yet. If they become available as Nix packages, move them to `home.packages` for better reproducibility.
- **Cascadia Code Nerd Font**: install on both sides — Windows Terminal needs it for the Starship prompt and Zellij icons to render correctly.
- **Podman on WSL**: `podman machine init` does not apply on Linux (that's for macOS/Windows only); on WSL, Podman runs directly, rootless, with no extra VM.
- **Git mergetool/difftool**: configured to use VS Code (`code --wait`) for both merge and diff, since no dedicated tool is installed.
- **`~/cloude`**: created empty as a single cloud connectivity mount point. Add subdirectories (`google/`, `dropbox/`, etc.) manually as needed. The recommended tool for syncing is **rclone** (supports Google Drive, Dropbox, and dozens of other providers, and runs well inside WSL).
- **SQL terminal access**: `postgresql_16` provides the `psql` client and `pgcli` adds interactive autocompletion — both complement DBeaver. The `postgresql_16` package includes the server binary but no service is started automatically.
- **Obsidian on WSL**: runs via WSLg (native GUI support in WSL2, included in Windows 11). Keep the vault inside the Linux filesystem (`~/obsidian`) — accessing it via `/mnt/c/...` is significantly slower for small-file I/O, which is exactly Obsidian's usage pattern. If you also run Obsidian on the Windows side, only open the vault from one side at a time to avoid write conflicts.

## Adding a new WSL tool

1. Add the package to `home.packages` in `wsl-nix/home.nix`.
2. Run `home-manager switch --flake .`
3. `git add . && git commit -m "add X" && git push`
4. On other machines: `git pull && home-manager switch --flake .`
