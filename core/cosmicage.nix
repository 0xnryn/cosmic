# Provides an option for declaring cryptographic identities and secret access policies.
# These rules are compiled into a format readable by the agenix CLI and exposed 
# under `#agenixSecrets` and `#agenixSecretsByTag`.

# Notice the @flakeScope capture here! This lets us bridge the Flake and the OS.
{ inputs, lib, config, ... }@flakeScope: {
  options.configurations.secrets = {
    identities = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            publicKey = lib.mkOption { type = lib.types.str; };
            tags = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
          };
        }
      );
      default = {};
    };

    policyGroups = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            basePath = lib.mkOption { type = lib.types.str; };
            files = lib.mkOption { type = lib.types.attrsOf (lib.types.listOf lib.types.str); default = {}; };
          };
        }
      );
      default = {};
    };

    policies = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            authorizedTags = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      );
      default = {};
    };
  };

  # ==========================================
  # 1. THE PATH COMPILER MACRO
  # ==========================================
  config.configurations.secrets.policies = let
    compiledPaths = lib.flatten (
      lib.mapAttrsToList (groupName: groupDef:
        lib.mapAttrsToList (fileName: tags:
          lib.nameValuePair "${groupDef.basePath}/${fileName}" { authorizedTags = tags; }
        ) groupDef.files
      ) config.configurations.secrets.policyGroups
    );
  in lib.listToAttrs compiledPaths;

  # ==========================================
  # 2. THE GLOBAL & TAG COMPILERS
  # ==========================================
  options.flake.agenixSecrets = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
  };

  config.flake.agenixSecrets =
    config.configurations.secrets.policies
    |> lib.mapAttrs (secretPath: policyDef: {
      publicKeys = let
        authorizedEntities = config.configurations.secrets.identities
          |> lib.filterAttrs (name: idDef: (builtins.length (lib.intersectLists idDef.tags policyDef.authorizedTags) > 0));
      in authorizedEntities |> lib.attrValues |> builtins.map (id: id.publicKey);
    });

  options.flake.agenixSecretsByTag = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.unspecified;
    default = {};
  };
    
  config.flake.agenixSecretsByTag = let
    policyTags = lib.flatten (lib.mapAttrsToList (path: policy: policy.authorizedTags) config.configurations.secrets.policies);
    identityTags = lib.flatten (lib.mapAttrsToList (name: id: id.tags) config.configurations.secrets.identities);
    allTags = lib.unique (policyTags ++ identityTags);
  in
  lib.genAttrs allTags (targetTag:
    config.configurations.secrets.policies
    |> lib.filterAttrs (secretPath: policyDef: let
        identitiesWithTag = lib.filterAttrs (n: id: builtins.elem targetTag id.tags) config.configurations.secrets.identities;
        hasAccess = lib.any (id: builtins.length (lib.intersectLists id.tags policyDef.authorizedTags) > 0) (lib.attrValues identitiesWithTag);
      in hasAccess || builtins.elem targetTag policyDef.authorizedTags
    )
    |> lib.mapAttrs (secretPath: policyDef: {
      publicKeys = let
        authorizedEntities = config.configurations.secrets.identities
          |> lib.filterAttrs (name: idDef: (builtins.length (lib.intersectLists idDef.tags policyDef.authorizedTags) > 0));
      in authorizedEntities |> lib.attrValues |> builtins.map (id: id.publicKey);
    })
  );

  # ==========================================
  # 3. THE MAGIC NIXOS WRAPPER (cosmic.secrets)
  # ==========================================
  # This module is injected into every NixOS machine. It intercepts your "file = string" 
  # and automatically finds the absolute path using the outer Flake's state.
  config.flake.nixosModules.cosmicage = { config, lib, ... }: {
    options.cosmicage.secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        options = {
          file = lib.mkOption { type = lib.types.str; description = "Just the raw filename (e.g., 'sudha.age')"; };
          path = lib.mkOption { type = lib.types.str; default = "/run/agenix/${name}"; };
          mode = lib.mkOption { type = lib.types.str; default = "0400"; };
          owner = lib.mkOption { type = lib.types.str; default = "root"; };
          group = lib.mkOption { type = lib.types.str; default = config.owner; };
        };
      }));
      default = {};
    };

    config.age.secrets = lib.mapAttrs (name: cfg: {
      file = let 
        policyPaths = builtins.attrNames flakeScope.config.configurations.secrets.policies;
        matchedPath = lib.findFirst (p: lib.hasSuffix "/${cfg.file}" p) null policyPaths;
      in 
        if matchedPath != null 
        then "${inputs.self}/${matchedPath}"
        else builtins.throw "\n[cosmicage error] The secret '${cfg.file}' was not declared in any policyGroup!\n";
      path = cfg.path;
      mode = cfg.mode;
      owner = cfg.owner;
      group = cfg.group;
    }) config.cosmicage.secrets;
  };

  # ==========================================
  # 4. THE NATIVE FLAKE APP (agenix-tag)
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
          REPO_ROOT=$(git rev-parse --show-toplevel)

          # --- NEW: AUTO-GENERATE DIRECTORIES ---
          echo "[*] Scanning for required secret directories..."
          nix eval --raw --impure --expr "
            let 
              flake = builtins.getFlake \"git+file://$REPO_ROOT\";
              target = if \"$TARGET_TAG\" == \"\" then flake.outputs.agenixSecrets else flake.outputs.agenixSecretsByTag.\"$TARGET_TAG\";
              dirs = builtins.map builtins.dirOf (builtins.attrNames target);
              uniqueDirs = builtins.foldl' (acc: e: if builtins.elem e acc then acc else acc ++ [e]) [] dirs;
            in builtins.concatStringsSep \"\\n\" uniqueDirs
          " | while read -r dir; do
              if [ -n "$dir" ]; then
                  mkdir -p "$REPO_ROOT/$dir"
              fi
          done

          if [ -z "$TARGET_TAG" ]; then
              echo "[*] Initiating Global Rekey..."
              TMPFILE=$(mktemp /tmp/agenix-tag-XXXXXX.nix)
              trap 'rm -f "$TMPFILE"' EXIT ERR INT TERM
              cat > "$TMPFILE" <<EOF
              let flake = builtins.getFlake "git+file://$REPO_ROOT"; in flake.outputs.agenixSecrets
EOF
              exec env RULES="$TMPFILE" agenix --rekey "$@"
          fi

          if [[ ! "$TARGET_TAG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
              echo "[!] CRITICAL: Invalid tag format. Aborting."
              exit 1
          fi

          TMPFILE=$(mktemp /tmp/agenix-tag-XXXXXX.nix)
        trap 'rm -f "$TMPFILE"' EXIT ERR INT TERM
        cat > "$TMPFILE" <<EOF
        let 
            flake = builtins.getFlake "git+file://$REPO_ROOT";
            tagMap = flake.outputs.agenixSecretsByTag;
        in 
            if builtins.hasAttr "$TARGET_TAG" tagMap then tagMap."$TARGET_TAG"
            else builtins.abort "\n[!] ERROR: Tag '$TARGET_TAG' not found.\n"
EOF
        
        # --- NEW: SMART ROUTING LOGIC ---
        if [[ " $* " =~ " -e " ]]; then
            echo "[*] Edit/Create Mode Initiated for Identity Tag: [$TARGET_TAG]"
            RULES="$TMPFILE" agenix "$@"
        else
            echo "[*] Targeted Rekey Initiated for Identity Tag: [$TARGET_TAG]"
            RULES="$TMPFILE" agenix --rekey "$@"
        fi
        '';
      });
    };
  };
}