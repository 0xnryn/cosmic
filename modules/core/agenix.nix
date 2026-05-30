# Provides an option for declaring cryptographic identities and secret access policies.
# These rules are compiled into a format readable by the agenix CLI and exposed 
# under `#agenixSecrets`.
{ lib, config, ... }:
{
  options.configurations.secrets = {
    # 1. THE IDENTITIES (Hardware & Humans)
    identities = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            publicKey = lib.mkOption { 
              type = lib.types.str; 
              description = "The SSH or TPM public key for this entity.";
            };
            tags = lib.mkOption { 
              type = lib.types.listOf lib.types.str; 
              default = []; 
              description = "A list of arbitrary tags (e.g., 'admin', 'ingress', 'database') defining this entity's capabilities.";
            };
          };
        }
      );
      default = {};
      description = "Declared human and machine identities.";
    };

    # 2. THE POLICIES (Access Control)
    policies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            requiredTags = lib.mkOption { 
              type = lib.types.listOf lib.types.str; 
              description = "The list of tags; an identity must possess AT LEAST ONE to decrypt this secret.";
            };
          };
        }
      );
      default = {};
      description = "Mapping of secret paths to the tags required to decrypt them.";
    };
  };

  # Declare the flake output for Agenix
  options.flake.agenixSecrets = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
    description = "The compiled secrets configuration evaluated by the agenix CLI.";
  };

  # 3. THE CRYPTOGRAPHIC COMPILER (Using Pipe Operators)
  config.flake.agenixSecrets =
    config.configurations.secrets.policies
    |> lib.mapAttrs (secretPath: policyDef: {
      
      publicKeys = let
        # Filter all identities down to only those authorized for this specific secret
        authorizedEntities = 
          config.configurations.secrets.identities
          |> lib.filterAttrs (name: idDef:
            (builtins.length (lib.intersectLists idDef.tags policyDef.requiredTags) > 0)
          );
      in
        # Extract the public keys from the authorized entities
        authorizedEntities
        |> lib.attrValues
        |> builtins.map (id: id.publicKey);

    });
}