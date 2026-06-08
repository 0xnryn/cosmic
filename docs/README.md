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