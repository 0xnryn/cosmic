{ pkgs, config, inputs, ... }:
let
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
    osConfig = config.flake.nixosConfigurations.${hostname}.config;
  };
in
{
  configurations.secrets.identities."sudhalaptoptpm" = {
    publicKey = "age1tag1qvyc9uwdu3d9jea3pdj53uak658zwe5mlfnk2gcc9acd0fu3s5hf5yf3e3k";
    tags = [ "sudhalaptopssh" "sudhalaptoptpm" ]; 
  };

  configurations.secrets.identities."sudhalaptopssh" = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDOJRuZDBhEn9Q37C0qZ8jMo6EMrTe7bzTT4hKcBMBN9 sudhalaptop";
    tags = [ "sudhalaptopssh" ]; 
  };
  
  configurations.secrets.policies = {
    "modules/machines/sudhalaptop/secrets/sudhalaptopssh.age" = {
      requiredTags = [ "root" "sudhalaptoptpm" ];
    };
  };
  
  configurations.nixos = {
    "laptop" = {
      system = "x86_64-linux";
      module = {
        age.identityPaths = [ 
          "/etc/sudhalaptoptpm"
        ];
        age.secrets."sudhalaptopssh" = {
          file = ./secrets/sudhalaptopssh.age;
          path = "/etc/ssh/ssh_host_ed25519_key"; 
          mode = "0600";
          owner = "root";
        };
        imports = with config.flake.nixosModules; [ 
          inputs.agenix.nixosModules.default
          laptop
          system
          ollama_cuda
          openwebui 
          docker
          sudha
          greetd
          tuigreet
          niri
        ];
      }; 
    }; 
  };

  configurations.home = {
    "sudha@laptop" = with config.flake.homeModules; mkUser "laptop" [
      sudhacli
      sudhagui
      helix
      zen-browser
      niri
      noctalia
    ];
  };  
}
