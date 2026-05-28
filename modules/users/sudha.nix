{ inputs, lib, config, ... }:
{

  flake.nixosModules.sudha = { config, pkgs, lib, ... }: {
    
    age.secrets."sudhauserpass" = {
      file = ../../secrets/sudhauserpass.age;
    };
    
    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
      hashedPasswordFile = config.age.secrets."sudhauserpass".path;
    };

    age.secrets."sshsudha" = {
      file = ../../secrets/sshsudha.age;
      mode = "0600";
      owner = "sudha";
      path = "/home/sudha/.ssh/id_ed25519";
    };
  };

  flake.homeModules.sudhacli = { pkgs, ... }:{
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
  
  flake.homeModules.sudhagui = { pkgs, ... }:{
    home.packages = with pkgs; [
      telegram-desktop
      steam-run
      prusa-slicer
      libreoffice-fresh
      zed-editor
      unrar
      affine
      vlc
      discord
      orca-slicer
    ];
  };
}
