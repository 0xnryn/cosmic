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
    allTags = lib.unique (
      lib.flatten (lib.mapAttrsToList (path: policy: policy.requiredTags) config.configurations.secrets.policies)
    );
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
  # 
  config.systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  config.perSystem = { pkgs, system, ... }: {
    apps.agenix-tag = {
      type = "app";
      program = lib.getExe (pkgs.writeShellApplication {
        name = "agenix-tag";
        # Added pkgs.git to runtimeInputs for the directory context fix
        runtimeInputs = [ inputs.agenix.packages.${system}.default pkgs.git ];
        text = ''
          TARGET_TAG=''${1:-}

          # [FIX 2: Strict-Mode Crash] Check argument count ($#) before shifting
          # to prevent 'set -u' from crashing on an unbound $1 variable.
          if [ "$#" -gt 0 ]; then shift; fi

          if [ -z "$TARGET_TAG" ]; then
              echo "[*] No identity tag specified. Initiating Global Rekey..."
              exec agenix --rekey "$@"
          fi

          # [FIX 1: Code Injection] Sanitize the tag strictly to alphanumeric + hyphens.
          # If an attacker tries to inject Nix code like 'laptop"; rm -rf /; "', it dies here.
          if [[ ! "$TARGET_TAG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
              echo "[!] CRITICAL: Invalid tag format. Tags must be alphanumeric. Aborting."
              exit 1
          fi

          echo "[*] Targeted Rekey Initiated for Identity Tag: [$TARGET_TAG]"
          
          # [FIX 3: Directory Context] Calculate absolute root dynamically using git.
          # Allows you to run `nix run .#agenix-tag` from ANY subfolder in the project.
          REPO_ROOT=$(git rev-parse --show-toplevel)

          # [FIX 4: State Leakage] Create the ephemeral file in the OS /tmp dir.
          # If the user force-kills the script, the git working tree remains clean.
          TMPFILE=$(mktemp /tmp/agenix-tag-XXXXXX.nix)
          trap 'rm -f "$TMPFILE"' EXIT ERR INT TERM

          # Inject variables directly into the Heredoc. $REPO_ROOT is passed as a string path.
          cat > "$TMPFILE" <<EOF
          let flake = builtins.getFlake "$REPO_ROOT";
          in flake.outputs.agenixSecretsByTag."$TARGET_TAG"
          EOF

          # Execute the compiled subset
          RULES="$TMPFILE" agenix --rekey "$@"
        '';
      });
    };
  };
}