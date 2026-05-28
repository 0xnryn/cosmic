{ config, inputs, ... }:
{
  configurations.nixos = {
    
    "laptop" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        inputs.agenix.nixosModules.default
        sudhalaptop
        # ollama_cuda
        openwebui 
        gnome
        system-users
        system
      ];
    };  
  
    "server" = {
      system = "x86_64-linux";
      module.imports = with config.flake.nixosModules; [ 
        inputs.agenix.nixosModules.default
        lenovoideapadgaming3-config
        lenovoideapadgaming3-disko
        lenovoideapadgaming3-nvidia
        ollama_cuda
        openwebui 
      ];
    };  
  };
}
