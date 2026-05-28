{ config, inputs, ... }:
{
  configurations.nixos = {
    
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        inputs.agenix.nixosModules.default
        laptop
        ollama_cuda
        openwebui 
        gnome
        system
        sudha
      ];
    };
 
    configurations.home = {
      "sudha@laptop" = with config.flake.homeModules; mkUser "laptop" [
        sudhacli
        sudhagui
        helix
        zen-browser
      ];
    };   
  };
}
