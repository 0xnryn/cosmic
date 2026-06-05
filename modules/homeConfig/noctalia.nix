{ ... }:
{
  flake.homeModules.noctalia = { pkgs, ... }: {
    
    # Install the official Nixpkgs version and its hardware dependencies
    home.packages = with pkgs; [
      noctalia-shell
      pamixer
      brightnessctl
      playerctl
    ];
    
  };
}