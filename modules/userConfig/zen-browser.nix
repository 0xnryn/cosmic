# Notice pkgs is REMOVED from this top line
{ inputs, ... }:
{
  flake.homeModules."zen-browser" = { pkgs, ... }: {
    home.packages = [
      inputs.zen-browser.packages.${pkgs.system}.default
    ];
    
    home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
          "${pkgs.kdePackages.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
  };
}