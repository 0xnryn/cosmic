{ ... }:
{
  flake.nixosModules.configuration = { pkgs, ... }: {
    
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
      trusted-users = [ "root" "sudha" ];
    };
    
    programs.nix-ld.enable = true;
    
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = "25.11";

    boot = {
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    hardware.bluetooth.enable = true;

    networking = {
      networkmanager.enable = true;
      firewall.enable = false;
      hostName = "laptop";
    };

    time.timeZone = "Asia/Kolkata";
    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";

    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
    };

    services = {
      printing.enable = true;
      pipewire = {
        enable = true;
        pulse.enable = true;
        # ADD THESE THREE LINES:
        alsa.enable = true;
        alsa.support32Bit = true;
        wireplumber.enable = true; # The modern session manager that handles dynamic routing
      };
      openssh.enable = true;
      avahi = {
        enable = true;
        nssmdns4 = true; # Allows the laptop (and all nodes) to resolve .local
      };
    };
    
    virtualisation.docker = {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      tree 
      util-linux 
      vim 
      wget 
      curl 
      git 
      gptfdisk 
      htop 
      pciutils 
      home-manager
      cloudflared
      sops
      age
      ssh-to-age
    ];
  };
}