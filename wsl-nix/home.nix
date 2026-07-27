{ pkgs, lib, ... }:
{
  home.stateVersion = "24.11";
  home.username = "djanr2";
  home.homeDirectory = "/home/djanr2";

  # ---------------------------------------------------------------
  # Paquetes base del ambiente
  # ---------------------------------------------------------------
  home.packages = with pkgs; [
    # --- Editor ligero ---
    helix       # editor moderno en terminal: LSP + treesitter incluidos, sin configuración extra
    openssl     # OpenSSL 3.x (versión activa con soporte de seguridad)

    # --- Terminal / multiplexor ---
    zellij

    # --- Contenedores ---
    podman
    podman-compose

    # --- Base de datos ---
    dbeaver-bin
    postgresql_16              # incluye el cliente `psql`
    pgcli                       # cliente interactivo con autocompletado

    # --- Control de versiones ---
    git
    home-manager

    # --- Gestores de versión ---
    mise                      # Java, Node (y otros)
    uv                         # Python

    # --- Navegadores ---
    google-chrome

    # --- IA local ---
    ollama

    # --- Documentación ---
    obsidian                    # gestiona los .md directamente desde Linux (vault en ~/obsidian)

    # --- Utilidades generales ---
    ripgrep
    fzf
    fd
    nmap                          # scanner de puertos / descubrimiento de red
    jq
    httpie                      # cliente HTTP legible: http POST api.com/users name=Juan
    unzip
    wget
    coreutils

    # --- Runtime para herramientas AI CLI (npm) ---
    nodejs_22
  ];

  # ---------------------------------------------------------------
  # Estructura de directorios base
  # ---------------------------------------------------------------
  home.file."projects/.keep".text = "";
  home.file."obsidian/.keep".text = "";
  home.file."downloads/.keep".text = "";

  # Punto único de montaje/enlace para conectividad con la nube
  # (subcarpetas como google/, dropbox/, etc. se agregan manualmente al usarlas)
  home.file."cloude/.keep".text = "";

  # Register fish in /etc/shells and set it as the login shell
  home.activation.setFishAsDefaultShell = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    FISH="${pkgs.fish}/bin/fish"
    if ! /usr/bin/grep -qF "$FISH" /etc/shells 2>/dev/null; then
      echo "$FISH" | /usr/bin/sudo /usr/bin/tee -a /etc/shells >/dev/null
    fi
    if [ "$SHELL" != "$FISH" ]; then
      /usr/bin/sudo /usr/bin/chsh -s "$FISH" "$USER"
    fi
  '';

  home.activation.installAiCliTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.nodejs_22}/bin:$PATH"
    npm install -g --prefix "$HOME/.npm-global" \
      @anthropic-ai/claude-code \
      opencode-ai \
      @openai/codex
  '';

  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  # ---------------------------------------------------------------
  # Git
  # ---------------------------------------------------------------
  programs.git = {
    enable = true;
    userName = "Tu Nombre";
    userEmail = "tu@email.com";
    extraConfig = {
      init.defaultBranch = "main";
      merge.tool = "vscode";
      mergetool."vscode".cmd = "code --wait $MERGED";
      diff.tool = "vscode";
      difftool."vscode".cmd = "code --wait --diff $LOCAL $REMOTE";
    };
  };

  # ---------------------------------------------------------------
  # mise: versiones por defecto (ajustables por proyecto con .mise.toml)
  # ---------------------------------------------------------------
  home.file.".config/mise/config.toml".text = ''
    [tools]
    java = "temurin-21"
    node = "22"

    [settings]
    experimental = true
  '';

  # ---------------------------------------------------------------
  # Zellij: layout base
  # ---------------------------------------------------------------
  home.file.".config/zellij/config.kdl".text = ''
    theme "default"
    default_shell "fish"
    pane_frames true
  '';

  # ---------------------------------------------------------------
  # Shell
  # ---------------------------------------------------------------
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      proj = "cd ~/projects";
    };
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      fish_add_path /nix/var/nix/profiles/default/bin
      fish_add_path $HOME/.nix-profile/bin
      fish_add_path $HOME/.npm-global/bin
    '';
    shellAliases = {
      ll = "ls -la";
      gs = "git status";
      proj = "cd ~/projects";
    };
  };

  # Atuin replaces Ctrl+R with a searchable, syncable command history
  programs.atuin = {
    enable = true;
  };

  programs.starship.enable = true; # prompt, combina bien con la Nerd Font
}
