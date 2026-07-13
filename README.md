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

## Personalizar por entorno (antes de aplicar)

Este repo se pensó para replicarse en distintas máquinas/ambientes (personal,
laboral, etc.), y algunos valores cambian según dónde lo apliques. Edita estos
4 puntos en `wsl-nix/home.nix` y `wsl-nix/flake.nix` cada vez que lo uses en
un entorno nuevo:

| Archivo | Campo | Cambia por entorno | Valor actual |
|---|---|---|---|
| `wsl-nix/home.nix` | `home.username` | Sí — usuario de Linux que te dé la empresa/máquina | `djanr2` |
| `wsl-nix/home.nix` | `home.homeDirectory` | Sí — debe ser `/home/<mismo usuario de arriba>` | `/home/djanr2` |
| `wsl-nix/flake.nix` | `homeConfigurations."..."` | Sí — mismo usuario que `home.username`, deben coincidir | `"djanr2"` |
| `wsl-nix/home.nix` | `programs.git.userEmail` | Sí — mail corporativo en ambientes de trabajo | `djanr2@gmail.com` |
| `wsl-nix/home.nix` | `programs.git.userName` | **No** — se mantiene igual en todos los entornos | `Juan Alfredo Nunez Rodriguez` |

Los tres primeros (`username`, `homeDirectory`, `homeConfigurations`) siempre
deben tener el mismo valor entre sí — si no coinciden, `home-manager switch`
falla al no encontrar la configuración.

## Aplicar en Windows

```powershell
winget configure --file windows\entorno.dsc.yaml --accept-configuration-agreements
```

Esto instala VS Code, Brave/Chrome, y habilita WSL.

> **Fuente:** `entorno.dsc.yaml` no instala Hack Nerd Font — se asume que ya
> la tienes en Windows (la usas con starship). El lado WSL instala la misma
> fuente vía Nix, ver notas abajo.

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
   git clone git@github.com:djanr2/dev.environment.git ~/entorno-dev
   cd ~/entorno-dev/wsl-nix
   nix run home-manager/master -- switch --flake .#djanr2
   ```

## Notas importantes antes de usar esto tal cual

- **Nombres de paquetes verificados contra nixos-24.05**: todos los paquetes de
  `home.packages` existen en esa revisión, con una excepción: los paquetes
  individuales `nerd-fonts.<nombre>` (ej. `nerd-fonts.hack`, `nerd-fonts.caskaydia-cove`)
  no existen todavía en 24.05 (esa reestructuración de nerdfonts llegó a nixpkgs a
  mediados de 2025). Por eso `home.nix` usa el paquete monolítico `nerdfonts` con
  `nerdfonts.override { fonts = [ "Hack" ]; }` — nombre verificado en
  `pkgs/data/fonts/nerdfonts/shas.nix` de esa revisión. Si en el futuro subes la
  revisión de nixpkgs, puedes migrar a `nerd-fonts.hack`.
- **Claude Code, OpenCode, Codex CLI**: se instalan vía npm en el paso de activación porque
  no siempre están empaquetados de forma estable en nixpkgs. Si en tu revisión ya existen
  como paquetes Nix, muévelos a `home.packages` para mayor reproducibilidad.
- **Fuente (Hack Nerd Font) — Windows vs. WSL**: para lo que ves en la terminal
  (prompt de starship, íconos de zellij) basta con tenerla instalada en Windows,
  porque Windows Terminal es quien la dibuja, sin importar si la shell es
  PowerShell o WSL. El lado Nix la instala aparte porque las apps gráficas de
  WSLg (como `sublime4` abierto desde WSL) usan el stack de fuentes de Linux
  (fontconfig), no el de Windows — por eso hace falta en ambos lados.
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
