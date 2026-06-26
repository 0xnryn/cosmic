# modules/nixondroid.nix
{ lib, config, inputs, ... }:
{
  options.configurations.nixondroid = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options = {
          # Default to aarch64-linux, but allow overriding
          system = lib.mkOption {
            type = lib.types.str;
            default = "aarch64-linux";
            description = "The architecture for this Nix-on-Droid host.";
          };
          module = lib.mkOption {
            type = lib.types.deferredModule;
          };
        };
      }
    );
  };

  config.flake = {
    nixOnDroidConfigurations = lib.flip lib.mapAttrs config.configurations.nixondroid (
      name: { system, module }: inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = import inputs.nixpkgs { inherit system; };
        modules = [ module ];
        extraSpecialArgs = { inherit inputs; };
      }
    );
  };
}