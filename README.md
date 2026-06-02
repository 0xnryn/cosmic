# NIXOS // DENDRITIC

Forget fragile dotfiles and manual setups. Dendritic is a mathematically sealed, zero-touch provisioning engine designed to manage a multi-node fleet.

We don't write boilerplate here. We use `import-tree` to automatically traverse the `modules/` directory, treating infrastructure as a dynamically evaluated dependency graph. You define the hardware, assert the cryptographic perimeter, and the flake compiles the rest.

---

## The Core Engine

The foundational logic lives in `modules/core/`. These aren't just config files; they are compiler macros that abstract away the raw Flake outputs.

* **The OS Compiler (`core/nixos.nix`):** Wraps standard `nixosConfigurations`. It lets you define architecture (`system = "x86_64-linux"`) natively and transparently injects Agenix binaries to support TPM2 decryption right at the bootloader level.


* **The User Space Injector (`core/home.nix`):** Abstracts `homeConfigurations`. Crucially, this macro catches the evaluated OS configuration and forces it down into the Home Manager scope (`extraSpecialArgs = { inherit osConfig; }`). This means your local user environments can dynamically read system-level hardware secrets without hardcoding paths.



---

## Wiring a Node

You construct a machine by snapping modules together under the `configurations` namespace.

Here is exactly how you spin up a new rig (e.g., `modules/machines/workstation.nix`):

```nix
{ config, inputs, ... }:
let
  # The scaffold function that bridges NixOS and Home Manager
  mkUser = hostname: modules: {
    pkgs = inputs.nixpkgs.legacyPackages.${config.configurations.nixos.${hostname}.system};
    module = { imports = modules; };
    osConfig = config.flake.nixosConfigurations.${hostname}.config;
  };
in
{
  # 1. Forge the Metal (OS Level)
  configurations.nixos = {
    "workstation" = {
      system = "x86_64-linux";
      module = {
        imports = with config.flake.nixosModules; [ 
          inputs.agenix.nixosModules.default
          hardware-profile-x     # Drive layout, TPM bindings
          system-defaults        # Networking, timezone
          desktop-environment    # Wayland, Plasma
        ];
        
        # Lock the node to its specific physical identity
        age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      }; 
    }; 
  };

  # 2. Project the User Space (Home Manager Level)
  configurations.home = {
    "admin@workstation" = with config.flake.homeModules; mkUser "workstation" [
      cli-environment
      gui-applications
      editor-configs
    ];
  };  
}

```

---

## Cryptographic RBAC (The Vault)

Standard `agenix` setups break down at scale because you have to manually maintain lists of SSH keys for every single secret.

We engineered a **Role-Based Access Control (RBAC) Compiler** directly into the flake (`core/agenix.nix`). It routes secrets mathematically using associative **Tags**.

### 1. The Actors (Identities)

You register physical hardware nodes and human admins by assigning them capability tags (like `admin` or `database-node`).

```nix
configurations.secrets.identities."admin-laptop" = {
  publicKey = "ssh-ed25519 AAAAC3Nz...";
  tags = [ "global-admin" "developer" ];
};

```

### 2. The Perimeter (Policies)

Instead of assigning public keys to a file, you map required tags to a secret path. During evaluation, the flake intersects the identities and policies to generate the final cryptographic ledger.

```nix
configurations.secrets.policies = {
  "secrets/api-keys.age".requiredTags = [ "global-admin" "web-server" ];
};

```

*Result: If an identity possesses `global-admin` OR `web-server`, it gains decryption clearance.*

### 3. Surgical Rekeying (`agenix-tag`)

If you add a new server to the fleet, you don't want to rekey the entire repository (which would require every admin's physical hardware key).

The core framework exposes a custom native app called `agenix-tag`. It compiles an isolated subset of the secret matrix based on the tag you target, allowing you to rekey surgically without touching unrelated secrets.

**Execution:**

```bash
# Global Rekey (Requires all keys)
nix run .#agenix-tag

# Surgical Rekey (Only touches secrets bound to the 'web-server' tag)
nix run .#agenix-tag -- web-server

```

---

## Operational Runbook

When deploying or modifying nodes, use these standardized commands to generate secure credentials, bind hardware identities, and manage cryptographic boundaries.

### Secrets Management

**1. Generate Secure Passphrases & Hashes**
Use these for system passwords or LUKS passphrases:

```bash
# Generate a random, memorable secure passphrase
nix-shell -p phraze --run "phraze -w 6 -n 10 -s ' ' -l m"

# Generate a SHA-512 hashed password for NixOS (users.users.<name>.hashedPassword)
nix run nixpkgs#mkpasswd -- -m sha-512

```

**2. Generate Identity Keys (SSH)**

```bash
# Generate a new SSH key for a user/admin
ssh-keygen -t ed25519 -C "<username>" -f secrets/<username>/<key-name>

```

**3. Agenix Secret Editing & Rekeying**

```bash
# Create or edit a specific secret file
ssh-agent bash -c 'ssh-add secrets/<admin-key> && nix shell github:ryantm/agenix --command agenix -e secrets/<new_secret_name>.age'

# Execute a Global Rekey (ensure your SSH agent is loaded)
ssh-agent bash -c 'ssh-add secrets/<admin-key> && nix shell github:ryantm/agenix --command agenix --rekey'

# Execute a Surgical Rekey targeting a specific identity tag
ssh-agent bash -c 'ssh-add secrets/<admin-key> && nix run .#agenix-tag -- <target-tag>'

```

> *Note: Replace `agenix-tag` with your specific flake app alias if different.*

### Hardware Bindings (TPM & Secure Boot)

**1. Provisioning a TPM Identity**
To tie a node's decryption capabilities directly to its physical TPM chip:

```bash
# Generate the TPM-bound age key
sudo age-plugin-tpm --generate -o /etc/<node>-tpm

# Secure the generated identity file
sudo chmod 600 /etc/<node>-tpm
sudo chown root:root /etc/<node>-tpm

```

**2. Secure Boot & Disk Encryption (LUKS)**
Ensure your boot sequence is mathematically sealed:

```bash
# Verify Secure Boot status
sudo nix run nixpkgs#sbctl -- status

# Wipe existing TPM LUKS slots before binding
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/<encrypted-partition>

# Bind LUKS decryption to TPM PCR 7 (Secure Boot) requiring a PIN
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/<encrypted-partition>

```

---

To ensure I haven't made any structural assumptions that conflict with your vision, would you prefer these commands stay bundled together in this "Operational Runbook" section at the bottom, or would you rather I weave them into the specific architectural sections above (e.g., putting the TPM commands directly under the "Cryptographic RBAC" heading)?