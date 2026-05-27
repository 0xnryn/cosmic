{ config, ... }:
{
  configurations.nixos = {
    
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        lenovoideapadgaming3-config
        lenovoideapadgaming3-disko
        lenovoideapadgaming3-nvidia
        ollama_cuda
        openwebui 
        gnome
      ];
    };  
  
    "server" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        lenovoideapadgaming3-config
        lenovoideapadgaming3-disko
        lenovoideapadgaming3-nvidia
        ollama_cuda
        openwebui 
      ];
    };  
  };
}