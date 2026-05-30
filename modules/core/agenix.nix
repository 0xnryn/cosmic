# Provides an option for declaring cryptographic identities and secret access policies.
# These rules are compiled into a format readable by the agenix CLI and exposed 
# under `#agenixSecrets`.
{ inputs, lib, config, ... }:
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

    # 4. THE SCOPED COMPILERS (For Targeted Identity Rekeying)
    options.flake.agenixSecretsByTag = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      description = "Agenix secrets filtered and isolated by specific identity tags.";
    };
  
    config.flake.agenixSecretsByTag = 
    let
      # Extract all unique tags used across all policies
      allTags = lib.unique (
        lib.flatten (lib.mapAttrsToList (path: policy: policy.requiredTags) config.configurations.secrets.policies)
      );
    in
    # Generate a dedicated vault map for every single tag
    lib.genAttrs allTags (tag:
      config.configurations.secrets.policies
      # Step 1: Isolate only the policies that allow this specific tag
      |> lib.filterAttrs (secretPath: policyDef: builtins.elem tag policyDef.requiredTags)
      # Step 2: Compile the public keys for those isolated policies
      |> lib.mapAttrs (secretPath: policyDef: {
        publicKeys = let
          authorizedEntities = config.configurations.secrets.identities
            |> lib.filterAttrs (name: idDef: (builtins.length (lib.intersectLists idDef.tags policyDef.requiredTags) > 0));
        in
          authorizedEntities |> lib.attrValues |> builtins.map (id: id.publicKey);
      })
    );

  perSystem = { pkgs, system, ... }: {
    apps.agenix-tag = {
      type = "app";
      program = lib.getExe (pkgs.writeShellApplication {
        name = "agenixrekey";
        runtimeInputs = [ inputs.agenix.packages.${system}.default ];
        text = ''
          TARGET_TAG=''${1:-}

          # Shift the arguments so $1 (the tag) is removed, 
          # leaving only extra flags like "-i path/to/key" in $@
          if [ -n "$1" ]; then shift; fi

          if [ -z "$TARGET_TAG" ]; then
              echo "[*] No identity tag specified. Initiating Global Rekey..."
              # Pass any extra flags directly to agenix
              exec agenix --rekey "$@"
          fi

          echo "[*] Targeted Rekey Initiated for Identity Tag: [$TARGET_TAG]"
          
          TMPFILE=$(mktemp .rekey-XXXXXX.nix)
          trap 'rm -f "$TMPFILE"' EXIT ERR INT TERM

          cat > "$TMPFILE" <<EOF
          let flake = builtins.getFlake (builtins.toString ./.);
          in flake.outputs.agenixSecretsByTag."$TARGET_TAG"
          EOF

          # Pass the ephemeral config AND any extra flags (like -i) to agenix
          agenix -c "$TMPFILE" --rekey "$@"
        '';
      });
    };
  };
}