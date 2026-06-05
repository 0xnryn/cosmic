{ ... }:{
  flake.nixosModules.niri = { pkgs, ... }: {
    
    programs.niri.enable = true;
    
    # Required for GTK Dark Mode
    programs.dconf.enable = true;
    
    # GNOME Nautilus Superpowers (Trash, USBs, Thumbnails)
    services.gvfs.enable = true; 
    services.tumbler.enable = true; 

    # --- THE STRICT GNOME PORTAL ROUTING ---
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
      ];
      config.niri = {
        # Instructs the system to prefer the GNOME UI for all dialogs
        default = [ "gnome" "gtk" ];
      };
    };

    # KDE Polkit Agent (Authentication Dialogs)
    systemd.user.services.polkit-kde-authentication-agent-1 = {
      description = "polkit-kde-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}