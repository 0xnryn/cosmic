{ config, inputs, ... }:
let
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
  };
in
{
  configurations.home = {
    "sudha@laptop" = with config.flake.homeModules; mkUser "laptop" [
      cli
      gui
      helix
      zen-browser
    ];

    "sudha@server" = with config.flake.homeModules; mkUser "server" [
      cli
      helix
    ];
  };

  flake.nixosModules.system-users = { config, pkgs, lib, ... }: {
  
    age.secrets."rootuserpass" = {
      file = ../../secrets/rootuserpass.age;
    };

    age.secrets."sudhauserpass" = {
      file = ../../secrets/sudhauserpass.age;
    };

    users.users.root = {
      hashedPasswordFile = config.age.secrets."rootuserpass".path;
    };

    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
      hashedPasswordFile = config.age.secrets."sudhauserpass".path;
    };

    age.secrets."sudha-ssh" = {
      file = ../../secrets/sshsudha.age;
      mode = "0600";
      owner = "sudha";
      path = "/home/sudha/.ssh/id_ed25519";
    };

    virtualisation.vmVariant = {
      users.users.root.hashedPasswordFile = pkgs.lib.mkForce null;
      users.users.sudha.hashedPasswordFile = pkgs.lib.mkForce null;
      
      users.users.root.initialPassword = "root";
      users.users.sudha.initialPassword = "test";

      systemd.services.agenix.enable = lib.mkForce false;
    };
  };
}