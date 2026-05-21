{ config, ... }:
let
  m = config.flake.nixosModules;
in
{
  configurations.nixos = {
    
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with m; [ 
        configuration 
        disko
        plasma 
        nvidia
        ollama_cuda
        openwebui 
      ];
    };    
  };
}