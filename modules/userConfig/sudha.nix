{ inputs, lib, config, ... }:
{
  flake.homeModules.sudhacli = { pkgs, osConfig, ... }:{
    nixpkgs.config.allowUnfree = true;
    home.username = "sudha";
    home.homeDirectory = "/home/sudha";
    home.stateVersion = "25.11";
    programs.home-manager.enable = true;
    home.packages = with pkgs; [
      tree
      util-linux
      wget
      curl
      git
      gptfdisk
      htop
      fastfetch
      android-tools
      sops
      pciutils
      mosquitto
      nixd
      nil
      cloudflared
      cachix
      python3
      espeak-ng
      uv
      pulseaudio 
      alsa-utils
      pipewire
      netcat-gnu
      unrar
      gh
      jq
      pwgen
    ];
    
    programs.git = {
      enable = true;
      settings.user = {
        name = "sudhanshunitinatalkar";
        email = "atalkarsudhanshu@proton.me";
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          IdentityFile = osConfig.age.secrets."sshsudha".path;
          # restore any defaults you want to keep
          AddKeysToAgent = "yes";
          ServerAliveInterval = 60;
        };
      };
    };
  };
  
  flake.homeModules.sudhagui = { pkgs, ... }:{
    home.packages = with pkgs; [
      telegram-desktop
      steam-run
      prusa-slicer
      libreoffice-fresh
      # vscode
      zed-editor
      unrar
      affine
      vlc
      discord
      jdk25
      orca-slicer
      google-chrome
      arduino-ide
    ];
  };
}
