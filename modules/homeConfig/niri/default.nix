{ ... }:
{
  flake.homeModules.niri = { pkgs, ... }: {
    
    # 1. Install the core Niri package
    home.packages = with pkgs; [
      niri
    ];

    # 2. Symlink the local KDL file to your Home directory and FORCE overwrite
    xdg.configFile."niri/config.kdl" = {
      source = ./config.kdl;
      force = true; # Tells Home Manager to ruthlessly overwrite the blocking file
    };
  };
}