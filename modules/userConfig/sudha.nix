{ inputs, lib, config, ... }:
{
  flake.homeModules.cli = { pkgs, ... }:{
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
  };
  
  flake.homeModules.gui = { pkgs, ... }:{
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
