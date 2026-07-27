{ pkgs, lib, ... }:
{
  home.stateVersion = "24.05";
  home.username = "tuusuario";
  home.homeDirectory = "/home/tuusuario";

  # ---------------------------------------------------------------
  # Paquetes base del ambiente
  # ---------------------------------------------------------------
  home.packages = with pkgs; [
    # --- Editor ligero ---
    sublime4                # `subl archivo.txt` desde terminal (GUI vía WSLg)

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

    # --- Gestores de versión ---
    mise                      # Java, Node (y otros)
    uv                         # Python

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

    # --- Fuente de desarrollo ---
    nerd-fonts.caskaydia-cove  # Cascadia Code Nerd Font
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

  # ---------------------------------------------------------------
  # Herramientas de IA que solo se distribuyen vía npm
  # (Claude Code, OpenCode, Codex CLI no están empaquetadas en nixpkgs
  # de forma estable todavía — se instalan como paso de activación)
  # ---------------------------------------------------------------
  home.packages = [ pkgs.nodejs_22 ];

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
    default_shell "zsh"
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

  programs.starship.enable = true; # prompt, combina bien con la Nerd Font
}
