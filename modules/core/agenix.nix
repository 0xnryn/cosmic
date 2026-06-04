# Provides an option for declaring cryptographic identities and secret access policies.
# These rules are compiled into a format readable by the agenix CLI and exposed 
# under `#agenixSecrets` and `#agenixSecretsByTag`.

{ inputs, lib, config, ... }:{
  options.configurations.secrets = {
    # ==========================================
    # 1. THE IDENTITIES (Hardware & Humans)
    # ==========================================
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
              description = "Arbitrary tags (e.g., 'admin', 'laptop') defining capabilities.";
            };
          };
        }
      );
      default = {};
      description = "Declared human and machine identities.";
    };

    # ==========================================
    # 2. THE POLICIES (Access Control)
    # ==========================================
    policies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            requiredTags = lib.mkOption { 
              type = lib.types.listOf lib.types.str; 
              description = "An identity must possess AT LEAST ONE of these tags to decrypt.";
            };
          };
        }
      );
      default = {};
      description = "Mapping of secret paths to the tags required to decrypt them.";
    };
  };

  # ==========================================
  # 3. THE GLOBAL CRYPTOGRAPHIC COMPILER
  # ==========================================
  options.flake.agenixSecrets = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
    description = "The global secrets configuration evaluated by the agenix CLI.";
  };

  config.flake.agenixSecrets =
    config.configurations.secrets.policies
    |> lib.mapAttrs (secretPath: policyDef: {
      publicKeys = let
        authorizedEntities = 
          config.configurations.secrets.identities
          |> lib.filterAttrs (name: idDef:
            (builtins.length (lib.intersectLists idDef.tags policyDef.requiredTags) > 0)
          );
      in
        authorizedEntities
        |> lib.attrValues
        |> builtins.map (id: id.publicKey);
    });

    # ==========================================
    # 4. THE SCOPED TAG COMPILER
    # ==========================================
    options.flake.agenixSecretsByTag = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.unspecified;
      default = {};
      description = "Agenix secrets filtered and isolated by specific identity tags.";
    };
    
    config.flake.agenixSecretsByTag = let
      policyTags = lib.flatten (lib.mapAttrsToList (path: policy: policy.requiredTags) config.configurations.secrets.policies);
      identityTags = lib.flatten (lib.mapAttrsToList (name: id: id.tags) config.configurations.secrets.identities);
      allTags = lib.unique (policyTags ++ identityTags);
    in
    lib.genAttrs allTags (tag:
      config.configurations.secrets.policies
      |> lib.filterAttrs (secretPath: policyDef: builtins.elem tag policyDef.requiredTags)
      |> lib.mapAttrs (secretPath: policyDef: {
        publicKeys = let
          authorizedEntities = config.configurations.secrets.identities
            |> lib.filterAttrs (name: idDef: (builtins.length (lib.intersectLists idDef.tags policyDef.requiredTags) > 0));
        in
          authorizedEntities |> lib.attrValues |> builtins.map (id: id.publicKey);
      })
    );
  
  # ==========================================
  # 5. THE NATIVE FLAKE APP (agenix-tag)
  # ==========================================
  
  config.perSystem = { pkgs, system, ... }: {
    apps.agenix-tag = {
      type = "app";
      program = lib.getExe (pkgs.writeShellApplication {
        name = "agenix-tag";
        runtimeInputs = [ inputs.agenix.packages.${system}.default pkgs.git ];
        text = ''
          TARGET_TAG=''${1:-}

          if [ "$#" -gt 0 ]; then shift; fi

          if [ -z "$TARGET_TAG" ]; then
              echo "[*] No identity tag specified. Initiating Global Rekey..."
              exec agenix --rekey "$@"
          fi

          if [[ ! "$TARGET_TAG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
              echo "[!] CRITICAL: Invalid tag format. Tags must be alphanumeric. Aborting."
              exit 1
          fi

          echo "[*] Targeted Rekey Initiated for Identity Tag: [$TARGET_TAG]"
          
          # Strictly enforces git auditability (will fail if not a git repo)
          REPO_ROOT=$(git rev-parse --show-toplevel)

          TMPFILE=$(mktemp /tmp/agenix-tag-XXXXXX.nix)
          trap 'rm -f "$TMPFILE"' EXIT ERR INT TERM

          # FIX: Graceful Error Handling for Typos via builtins.hasAttr
          cat > "$TMPFILE" <<EOF
          let 
            flake = builtins.getFlake "$REPO_ROOT";
            tagMap = flake.outputs.agenixSecretsByTag;
          in 
            if builtins.hasAttr "$TARGET_TAG" tagMap then
              tagMap."$TARGET_TAG"
            else
              builtins.abort "\n[!] ERROR: The tag '$TARGET_TAG' is not declared in any identity or policy.\n"
          EOF

          # Execute the compiled subset
          RULES="$TMPFILE" agenix --rekey "$@"
        '';
      });
    };
  };
}