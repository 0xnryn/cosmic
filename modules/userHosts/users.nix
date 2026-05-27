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
    imports = [ inputs.sops-nix.nixosModules.sops ];

    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Adjust path: userHosts is 2 folders deep (modules/userHosts/)
      defaultSopsFile = ../../secrets/passwords.yaml;
      defaultSopsFormat = "yaml";
    };

    sops.secrets.root = {
      neededForUsers = true;
    };

    # CRITICAL: neededForUsers must be true
    sops.secrets.sudha = {
      neededForUsers = true;
    };

    # Apply the SOPS passwords to the users
    users.users.root = {
      hashedPasswordFile = config.sops.secrets.root.path;
    };

    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
      hashedPasswordFile = config.sops.secrets.sudha.path;
    };

    # THE VM OVERRIDE: ONLY applies when running `nixos-rebuild build-vm`
    virtualisation.vmVariant = {
      users.users.root.hashedPasswordFile = pkgs.lib.mkForce null;
      users.users.sudha.hashedPasswordFile = pkgs.lib.mkForce null;
      
      users.users.root.initialPassword = "root";
      users.users.sudha.initialPassword = "test";
    };
  };
}