{ config, inputs, ... }:
let
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
    osConfig = config.flake.nixosConfigurations.${hostname}.config;
  };
in
{
  configurations.secrets.identities."laptop" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAg0BNZUo8/LJiRcyPPKW+6cryfwWTMHRUfv3kXJrYd0 laptop";
    tags = [ "laptop" ]; # Because it's an admin, it will automatically get access to everything.
  };
  
  configurations.secrets.policies = {
    "modules/machines/sudhalaptop/secrets/laptop.age" = {
      requiredTags = [ "root" "laptop" ];
    };
  };
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
      
      age.secrets."laptop" = {
        file = secrets/laptop/laptop.age;
        path = "/etc/ssh/ssh_host_ed25519_key"; 
        mode = "0600";
        owner = "root";
      };
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
