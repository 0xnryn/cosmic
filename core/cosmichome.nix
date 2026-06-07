# Provides an option for declaring Home Manager configurations.
# These configurations end up as flake outputs under `#homeConfigurations."<name>"`.
# A check for the activation package of each configuration also ends
# under `#checks.<system>."configurations:home:<name>"`.
{ lib, config, inputs, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = { };
    description = "Home Manager modules to be exported by the flake.";
  };

  options.configurations.home = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          # 1. We ONLY ask for the target NixOS host name
          hostName = lib.mkOption {
            type = lib.types.str;
            description = "The NixOS host this user configuration belongs to.";
          };
          # 2. And the list of Home Manager "bricks" (modules) to install
          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
            description = "List of Home Manager modules to import.";
          };
        };
      }
    );
  };

  config.flake = {
    homeConfigurations = lib.mapAttrs (name: hmConfig: 
      let
        # THE MAGIC: Cross-reference the NixOS tree to find the host's details
        hostSystem = config.configurations.nixos.${hmConfig.hostName}.system;
        
        # Instantiate the correct packages for that specific architecture
        nixpkgsInstance = inputs.nixpkgs.legacyPackages.${hostSystem};
        
        # Fetch the fully evaluated OS config for that specific host
        fetchedOsConfig = config.flake.nixosConfigurations.${hmConfig.hostName}.config;
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsInstance;
        
        # Inject the OS config and flake inputs globally into Home Manager
        extraSpecialArgs = { 
          osConfig = fetchedOsConfig; 
          inputs = inputs; 
        };
        
        # Pass the list of requested modules
        modules = hmConfig.modules;
      }
    ) config.configurations.home;

    checks =
      config.flake.homeConfigurations
      |> lib.mapAttrsToList (
        name: hm: {
          ${hm.pkgs.stdenv.hostPlatform.system} = {
            "configurations:home:${name}" = hm.activationPackage;
          };
        }
      )
      |> lib.mkMerge;
  };
}