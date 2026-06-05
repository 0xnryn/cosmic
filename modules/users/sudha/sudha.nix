{ inputs, lib, config, ... }:{
    
  configurations.secrets.identities."root" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQgPPuvnBiaK6z3ADBqY5l11oB6HHwm1rtUAEusMSlx root";
    tags = [ "root" ];
  };

  configurations.secrets.identities."sudhassh" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAPOVwS487rUg6zfTKdeRILuaF2MAkj+0Hb+VybiY/MK sudha";
    tags = [ "sudhassh" ];
  };

  # Protect your personal secrets
  configurations.secrets.policies = {
    "modules/users/sudha/secrets/sudhassh.age".requiredTags = [ "root" "sudhalaptopssh" ];
    "modules/users/sudha/secrets/sudhauserpass.age".requiredTags = [ "root" "sudhalaptopssh" "sudhassh" ];
  };

  flake.nixosModules.sudha = { config, pkgs, lib, ... }: {
    
    age.secrets."sshsudha" = {
      file = ./secrets/sudhassh.age;
      mode = "0600";
      owner = "sudha";
      path = "/home/sudha/.ssh/id_ed25519";
    };
    
    age.secrets."sudhauserpass" = {
      file = ./secrets/sudhauserpass.age;
    };
    
    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" ];
      hashedPasswordFile = config.age.secrets."sudhauserpass".path;
    };
  };

  flake.homeModules.sudhacli = { pkgs, osConfig, ... }:{
    nixpkgs.config.allowUnfree = true;
    home.username = "sudha";
    home.homeDirectory = "/home/sudha";
    home.stateVersion = "26.05";
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
      nautilus       # Modern GTK4 File Manager
      sushi          # File previewer (press Spacebar in Nautilus)
      loupe          # Hardware-accelerated Wayland image viewer
      evince         # Fast, minimal PDF reader
      baobab         # Beautiful disk usage analyzer
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
      obs-studio
      pavucontrol
    ];

    
  };
}
