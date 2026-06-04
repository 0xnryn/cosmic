{ config, inputs, ... }:
let
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
    osConfig = config.flake.nixosConfigurations.${hostname}.config;
  };
in
{
  configurations.nixos = {
    "server" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        inputs.agenix.nixosModules.default
        server
        sudha
        erpnext
      ];
    }; 
  };

  configurations.home = {
    "sudha@server" = with config.flake.homeModules; mkUser "server" [
      sudhacli
      helix
    ];
  };  
}
