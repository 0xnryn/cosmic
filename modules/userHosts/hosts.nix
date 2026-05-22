{ config, ... }:
let
  m = config.flake.nixosModules;
in
{
  configurations.nixos = {
    
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with m; [ 
        lenovoideapadgaming3-config
        lenovoideapadgaming3-disko
        lenovoideapadgaming3-nvidia
        ollama_cuda
        openwebui 
        plasma
      ];
    };    
  };
}