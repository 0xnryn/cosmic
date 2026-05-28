{ config, inputs, ... }:
let
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
  };
in
{
  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        inputs.agenix.nixosModules.default
        laptop
        system
        ollama_cuda
        openwebui 
        gnome
        sudha
      ];
    }; 
  };

  configurations.home = {
    "sudha@laptop" = with config.flake.homeModules; mkUser "laptop" [
      sudhacli
      sudhagui
      helix
      zen-browser
    ];
  };  
}
