{ config, inputs, ... }:
let
  hm = config.flake.homeModules;

  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
  };
in
{
  configurations.home = {
    "sudha@laptop" = with hm; mkUser "laptop" [
      cli
      gui
      helix
      zen-browser
    ];

    "sudha@server" = with hm; mkUser "server" [
      cli
      helix
    ];
  };

  flake.nixosModules.system-users = { config, pkgs, ... }: {
    
    # ==========================================
    # 1. THE AGENIX PASSWORD DECRYPTION
    # ==========================================
    # Unlike SOPS which uses one big YAML file, Agenix decrypts literal files.
    # We point to the encrypted hashes in your secrets folder.

    age.secrets."root-password" = {
      file = ../../secrets/root-password.age;
    };

    age.secrets."sudha-password" = {
      file = ../../secrets/sudha-password.age;
    };

    # ==========================================
    # 2. APPLYING PASSWORDS TO USERS
    # ==========================================
    
    users.users.root = {
      # Points to the decrypted file sitting in /run/agenix/root-password
      hashedPasswordFile = config.age.secrets."root-password".path;
    };

    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
      hashedPasswordFile = config.age.secrets."sudha-password".path;
    };

    # ==========================================
    # 3. THE VM OVERRIDE
    # ==========================================
    # ONLY applies when running `nixos-rebuild build-vm`
    virtualisation.vmVariant = {
      users.users.root.hashedPasswordFile = pkgs.lib.mkForce null;
      users.users.sudha.hashedPasswordFile = pkgs.lib.mkForce null;
      
      users.users.root.initialPassword = "root";
      users.users.sudha.initialPassword = "test";
    };
  };
}