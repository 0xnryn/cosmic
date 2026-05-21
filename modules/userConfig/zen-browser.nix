{ inputs, pkgs, ... }:
{
  flake.nixosModules.zen-browser = { ... }: {
    home.packages = [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
          "${pkgs.kdePackages.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
  };
}