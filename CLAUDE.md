# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Declarative dev environment for Windows + WSL. Two independent layers that are applied separately:

- **`windows/entorno.dsc.yaml`** — WinGet DSC manifest (VS Code, fonts, browsers, WSL bootstrap)
- **`wsl-nix/`** — Nix Home Manager config (entire WSL toolchain, dotfiles, shell, directory structure)

## Applying changes

**Windows layer:**
```powershell
winget configure --file windows\entorno.dsc.yaml --accept-configuration-agreements
```

**WSL layer (first time):**
```bash
nix run home-manager/master -- switch --flake .#tuusuario
```

**WSL layer (subsequent):**
```bash
home-manager switch --flake .
```

## Architecture

`flake.nix` pins `nixpkgs/nixos-24.05` and `home-manager`, then exports a single Home Manager configuration keyed to the username (`tuusuario`). `home.nix` is the single source of truth for everything inside WSL: packages, directory scaffolding, Git config, shell, prompt, terminal multiplexer, and an activation script that installs AI CLI tools via npm (Claude Code, OpenCode, Codex — not yet stable in nixpkgs).

## Personalizing before first apply

Replace all placeholders in `wsl-nix/home.nix` before applying:
- `tuusuario` → actual Linux username (appears in `home.username`, `home.homeDirectory`, and `flake.nix`)
- `"Tu Nombre"` and `"tu@email.com"` → real Git identity

`flake.nix` also uses `tuusuario` as the configuration key — keep it in sync with `home.nix`.

## Adding a new WSL tool

1. Add the package to `home.packages` in `wsl-nix/home.nix`
2. Run `home-manager switch --flake .` inside WSL
3. Commit and push; pull + re-run on other machines

Before adding, verify the exact package name with:
```bash
nix search nixpkgs <package>
```

## Key notes

- **nixpkgs channel**: pinned to `nixos-24.05` — package names may differ on other channels
- **AI CLI tools** (Claude Code, OpenCode, Codex) are installed via npm activation, not as Nix packages, because they aren't stably packaged yet; they land in `~/.npm-global/bin`
- **mise** manages Java (Temurin 21) and Node 22 globally; per-project overrides go in `.mise.toml`
- **Podman** runs rootless directly in WSL2 — no `podman machine init` needed (that's macOS/Windows only)
- **`~/cloude/`** is a placeholder mount point for cloud storage (rclone); subdirectories are added manually
