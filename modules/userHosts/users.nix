{ config, inputs, ... }:
let
  hm = config.flake.homeModules;

  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
  };
in
{
  configurations.home = {
    "sudha@laptop" = with hm; mkUser "laptop" [
      cli
      gui
      helix
      zen-browser
    ];

    "sudha@server" = with hm; mkUser "server" [
      cli
      helix
    ];
  };
}