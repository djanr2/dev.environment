# Entorno de desarrollo estándar — Windows + WSL

## Estructura

```
entorno-dev/
├── windows/
│   └── entorno.dsc.yaml      # Apps que se quedan en Windows (VS Code, fuente, StarUML, navegadores, WSL)
├── wsl-nix/
│   ├── flake.nix               # Fija nixpkgs + home-manager
│   └── home.nix                # Todo el toolchain de WSL, dotfiles, estructura de carpetas
└── README.md
```

## Qué se instala

### Windows (`entorno.dsc.yaml`)

| Herramienta | Descripción |
|---|---|
| Visual Studio Code | Editor principal |
| JetBrains Mono Nerd Font | Fuente para terminal (Starship + iconos de Zellij) |
| Brave | Navegador principal |
| Google Chrome | Navegador secundario (testing/QA) |
| WSL + Ubuntu | Instalado vía `wsl --install --no-launch` (puede requerir reinicio) |

### WSL — Nix Home Manager (`home.nix`)

**Editores y terminal**
- `sublime4` — editor ligero (`subl`, GUI vía WSLg)
- `zellij` — multiplexor de terminal

**Contenedores**
- `podman` + `podman-compose` — equivalente rootless a Docker (corre directo en WSL2, sin VM extra)

**Bases de datos**
- `dbeaver-bin` — cliente GUI universal (vía WSLg)
- `postgresql_16` — cliente `psql`
- `pgcli` — cliente interactivo con autocompletado y resaltado de sintaxis

**Gestores de versiones**
- `mise` — Java y Node (defecto: Temurin 21 y Node 22; override por proyecto con `.mise.toml`)
- `uv` — Python (gestión de versiones y entornos virtuales)

**IA local y CLI**
- `ollama` — modelos de lenguaje locales
- `@anthropic-ai/claude-code` *(npm)* — Claude Code CLI
- `opencode-ai` *(npm)* — OpenCode CLI
- `@openai/codex` *(npm)* — Codex CLI

**Documentación y notas**
- `obsidian` — vault en `~/obsidian` (GUI vía WSLg)

**Utilidades**
- `ripgrep`, `fzf`, `fd` — búsqueda rápida
- `jq` — procesamiento JSON
- `httpie` — cliente HTTP legible (`http POST api.com/...`)
- `nmap` — scanner de red/puertos
- `wget`, `unzip`, `coreutils`

**Shell y prompt**
- `zsh` con aliases (`ll`, `gs`, `proj`)
- `starship` — prompt configurable

**Estructura de directorios creada automáticamente**
```
~/projects/    # código
~/obsidian/    # vault de Obsidian
~/downloads/
~/cloude/      # punto de montaje para rclone (Google Drive, Dropbox, etc.)
```

---

## Aplicar en Windows

```powershell
winget configure --file windows\entorno.dsc.yaml --accept-configuration-agreements
```

Esto instala VS Code, la fuente, los navegadores y WSL. Si WSL requiere reinicio, el resto del manifiesto termina igual y WSL queda activo tras reiniciar.

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

- **Verifica nombres de paquetes**: nixpkgs cambia nombres de paquetes con el tiempo
  (ej. `nerd-fonts.caskaydia-cove`, `dbeaver-bin`, `sublime4`). Antes de aplicar, corre
  `nix search nixpkgs <paquete>` para confirmar el nombre exacto en tu revisión de nixpkgs.
- **Claude Code, OpenCode, Codex CLI**: se instalan vía npm en el paso de activación porque
  no siempre están empaquetados de forma estable en nixpkgs. Si en tu revisión ya existen
  como paquetes Nix, muévelos a `home.packages` para mayor reproducibilidad.
- **Cascadia Code Nerd Font**: instálala en ambos lados — Windows Terminal la necesita para
  el prompt (starship) y los íconos de zellij se vean bien.
- **Podman en WSL**: recuerda que `podman machine init` no aplica en Linux (eso es solo
  para macOS/Windows); en WSL, Podman corre directo, rootless, sin máquina virtual extra.
- **Git mergetool/difftool**: quedaron configurados para usar VS Code (`code --wait`) tanto
  para merge como para diff, ya que no hay una herramienta dedicada instalada aparte.
- **`~/cloude`**: se crea vacía como punto único de conectividad con la nube. Las subcarpetas
  (`google/`, `dropbox/`, etc.) las agregas manualmente cuando las vayas a usar. Cuando quieras
  que realmente sincronicen contenido, la herramienta recomendada es **rclone** (soporta Google
  Drive, Dropbox, y decenas de proveedores más, y corre bien dentro de WSL) — avísame cuando
  llegues a ese punto y lo agregamos.
- **Acceso SQL por terminal**: se agregó `postgresql_16` (trae el cliente `psql`) y `pgcli`
  (cliente interactivo con autocompletado y resaltado de sintaxis) como complemento de DBeaver.
  El paquete `postgresql_16` incluye también el binario del servidor, pero aquí solo se usa
  el cliente — no se levanta ningún servicio automáticamente.
- **Obsidian en WSL**: corre vía WSLg (soporte GUI nativo de WSL2, ya incluido en Windows 11).
  El vault vive en `~/obsidian`, dentro del filesystem de Linux — evita ponerlo en `/mnt/c/...`
  porque cruzar el límite Windows↔WSL es notablemente más lento para I/O de archivos pequeños,
  que es justo el patrón de uso de Obsidian. Recuerda que ya tienes Obsidian también en Windows
  (fuera de este archivo, instalado aparte); si administras el mismo vault desde ambos lados,
  hazlo siempre desde uno a la vez para evitar conflictos de escritura simultánea.

## Flujo para agregar una herramienta nueva

1. Edita `wsl-nix/home.nix` (agrega el paquete a `home.packages`).
2. `home-manager switch --flake .`
3. `git add . && git commit -m "agregar X" && git push`
4. En tus otras máquinas: `git pull && home-manager switch --flake .`
