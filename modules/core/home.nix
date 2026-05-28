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
          module = lib.mkOption {
            type = lib.types.deferredModule;
          };
          pkgs = lib.mkOption {
            type = lib.types.raw;
            description = "The instantiated nixpkgs to use for this configuration.";
          };
          # ADD THIS: Expose osConfig as a valid property for home configurations
          osConfig = lib.mkOption {
            type = lib.types.raw;
            default = {};
            description = "The evaluated NixOS configuration for the target host.";
          };
        };
      }
    );
  };

  config.flake = {
    homeConfigurations = lib.flip lib.mapAttrs config.configurations.home (
      # ADD osConfig to the parameters here
      name: { module, pkgs, osConfig }: inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        
        # INJECT THIS: Pass the NixOS config and flake inputs into Home Manager
        extraSpecialArgs = { 
          inherit osConfig inputs; 
        };
        
        modules = [ module ];
      }
    );

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