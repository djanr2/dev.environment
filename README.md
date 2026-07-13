# Entorno de desarrollo estándar — Windows + WSL

## Estructura

```
entorno-dev/
├── windows/
│   └── entorno.dsc.yaml      # Apps que se quedan en Windows (VS Code, navegadores, WSL)
├── wsl-nix/
│   ├── flake.nix               # Fija nixpkgs + home-manager
│   └── home.nix                # Todo el toolchain de WSL, dotfiles, estructura de carpetas
└── README.md
```

## Aplicar en Windows

```powershell
winget configure --file windows\entorno.dsc.yaml --accept-configuration-agreements
```

Esto instala VS Code, Brave/Chrome, y habilita WSL.

> **Pendiente:** la instalación automática de Cascadia Code Nerd Font se quitó
> de `entorno.dsc.yaml` porque no se encontró un id de winget confirmado.
> Instálala manualmente desde https://www.nerdfonts.com/font-downloads
> (variante **CaskaydiaCove**) o corre `winget search "nerd font"` para
> confirmar un id y volver a agregarla al DSC.

## Aplicar en WSL (Ubuntu)

1. Instalar Nix (si no lo tienes):
   ```bash
   sh <(curl -L https://nixos.org/nix/install) --daemon
   ```
2. Habilitar flakes (una sola vez):
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```
3. Clonar este repo y aplicar:
   ```bash
   git clone <tu-repo> ~/entorno-dev
   cd ~/entorno-dev/wsl-nix
   nix run home-manager/master -- switch --flake .#tuusuario
   ```

## Notas importantes antes de usar esto tal cual

- **Nombres de paquetes verificados contra nixos-24.05**: todos los paquetes de
  `home.packages` existen en esa revisión, con una excepción: `nerd-fonts.caskaydia-cove`
  no existe todavía (esa reestructuración de nerdfonts llegó a nixpkgs a mediados de 2025).
  Por eso `home.nix` usa el paquete monolítico `nerdfonts` con
  `nerdfonts.override { fonts = [ "CascadiaCode" ]; }`. Si en el futuro subes la revisión
  de nixpkgs, puedes volver a `nerd-fonts.caskaydia-cove` y correr
  `nix search nixpkgs <paquete>` para confirmar nombres actuales.
- **Claude Code, OpenCode, Codex CLI**: se instalan vía npm en el paso de activación porque
  no siempre están empaquetados de forma estable en nixpkgs. Si en tu revisión ya existen
  como paquetes Nix, muévelos a `home.packages` para mayor reproducibilidad.
- **Cascadia Code Nerd Font en Windows**: instálala manualmente por ahora (ver nota en
  "Aplicar en Windows" arriba) — Windows Terminal la necesita para que el prompt
  (starship) y los íconos de zellij se vean bien. El lado WSL ya la instala vía Nix.
- **Podman en WSL**: recuerda que `podman machine init` no aplica en Linux (eso es solo
  para macOS/Windows); en WSL, Podman corre directo, rootless, sin máquina virtual extra.
- **Git mergetool/difftool**: quedaron configurados para usar VS Code (`code --wait`) tanto
  para merge como para diff, ya que no hay una herramienta dedicada instalada aparte.
- **`~/cloude`**: se crea vacía como punto único de conectividad con la nube. Las subcarpetas
  (`google/`, `dropbox/`, etc.) las agregas manualmente cuando las vayas a usar. Cuando quieras
  que realmente sincronicen contenido, la herramienta recomendada es **rclone** (soporta Google
  Drive, Dropbox, y decenas de proveedores más, y corre bien dentro de WSL) — avísame cuando
  llegues a ese punto y lo agregamos.

## Flujo para agregar una herramienta nueva

1. Edita `wsl-nix/home.nix` (agrega el paquete a `home.packages`).
2. `home-manager switch --flake .`
3. `git add . && git commit -m "agregar X" && git push`
4. En tus otras máquinas: `git pull && home-manager switch --flake .`
