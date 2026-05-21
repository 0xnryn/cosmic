{ config, inputs, ... }:
let
  hm = config.flake.homeModules;

  mkUser = hostname: modules: {
    # MAGIC: This looks at hosts.nix, finds the matching hostname, and extracts the 'system' value!
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
  };

in
{
  configurations.home = {
    "sudha@laptop" = mkUser "laptop" [
      hm.cli
      hm.gui
      hm.helix
      hm.zen-browser
    ];

    "sudha@server" = mkUser "server" [
      hm.cli
      hm.helix
    ];
  };
}