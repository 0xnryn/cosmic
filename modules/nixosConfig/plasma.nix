{ ... }:
{
  flake.nixosModules.plasma = { pkgs, ... }:
  {
    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    # 1. The KDE Connect Fix (Firewall handling)
    programs.kdeconnect.enable = true;

    # 2. The GTK Bridge (State saving for non-KDE apps)
    programs.dconf.enable = true;

    # 3. The Bloat Purge (Strip unwanted default KDE apps)
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa       # Default music player
      discover    # KDE software center (useless on NixOS)
      konsole     # If you prefer Kitty/Alacritty
      # kate      # Uncomment if you strictly use Zed/Helix
    ];

    environment.systemPackages = with pkgs; [
      # Core KDE Utilities
      kdePackages.plasma-browser-integration
      kdePackages.kcalc
      kdePackages.kcharselect
      kdePackages.kcolorchooser
      kdePackages.kolourpaint
      kdePackages.ksystemlog
      kdePackages.sddm-kcm
      kdePackages.ktorrent
      kdePackages.isoimagewriter
      kdePackages.partitionmanager
      kdePackages.filelight
      
      # Development & Differencing
      kdiff3

      # Non-KDE graphical & Wayland packages
      hardinfo2
      wayland-utils
      wl-clipboard
    ];

    environment.sessionVariables = {
      # Forces Chromium/Electron apps to use native Wayland
      NIXOS_OZONE_WL = "1";
    };
  };
}