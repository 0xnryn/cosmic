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
          hostName = lib.mkOption {
            type = lib.types.str;
            description = "The NixOS host this user configuration belongs to.";
          };
          modules = lib.mkOption {
            type = lib.types.listOf lib.types.deferredModule;
            default = [];
            description = "List of Home Manager modules to import.";
          };
        };
      }
    );
    default = {}; 
  };
  config.flake = lib.mkIf (config.configurations.home != {}) {
    homeConfigurations = lib.mapAttrs (name: hmCfg: 
      let
        targetSystem = config.configurations.nixos.${hmCfg.hostName}.system;
        targetPkgs = inputs.nixpkgs.legacyPackages.${targetSystem};
        targetOsConfig = config.flake.nixosConfigurations.${hmCfg.hostName}.config;
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = targetPkgs;
        modules = [ { imports = hmCfg.modules; } ];
        extraSpecialArgs = { 
          osConfig = targetOsConfig; 
          inherit inputs; 
        };
      }
    ) config.configurations.home;
    checks = config.flake.homeConfigurations
      |> lib.mapAttrsToList (name: hm: {
        ${hm.pkgs.stdenv.hostPlatform.system}."configurations:home:${name}" = hm.activationPackage;
      })
      |> lib.mkMerge;
  };
}