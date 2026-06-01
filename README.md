# NixOS Dendritic

**NixOS Dendritic** is a highly modular, declarative, and cryptographically hardened Infrastructure-as-Code (IaC) repository. It manages a multi-node fleet using Nix Flakes, emphasizing Zero-Touch Provisioning (ZTP), hardware-bound secret management, and deterministic builds.

## System Architecture

This repository manages the following target hosts:

* **`laptop` (Mobile Workstation):** A cryptographically sealed workstation featuring UEFI Secure Boot (`lanzaboote`), TPM2-backed LUKS full-disk encryption bound to PCR 7, and hybrid graphics management (AMD iGPU + NVIDIA dGPU offloading). Heavily utilizes Wayland, GNOME/Plasma, and local AI (Ollama + OpenWebUI).
* **`server` (Headless Services Node):** A legacy-hardware server (BIOS/GRUB) utilizing headless remote provisioning. It hosts robust containerized workloads including a full ERPNext stack, Cloudflared Zero-Trust tunnels, and Tailscale networking.

## Repository Structure

The flake utilizes `import-tree` to automatically evaluate and compose the system from isolated modules.

```text
nixos-dendritic/
├── flake.nix                 # Central manifest and input definitions
├── secrets.nix               # Global cryptographic public key ledger
└── modules/
    ├── core/                 # Custom module orchestrators (Agenix, Home Manager, NixOS macros)
    ├── hardware/             # Bare-metal configurations, kernel modules, and Disko drive layouts
    ├── machines/             # High-level host definitions binding profiles together
    ├── nixosConfig/          # System-level services (Docker, Tailscale, Cloudflared, ERPNext)
    ├── homeConfig/           # User-level application configs (Helix, Zen Browser)
    └── users/                # User identities, groups, and SSH/Age configurations

```

## Cryptography & Secret Management

This repository employs a **Dual-Layer Secret Architecture** to ensure secrets never leak into the world-readable `/nix/store` or GitHub.

1. **System Identity (Agenix):** Used for core system secrets (user passwords, SSH private keys). Features a custom `agenix.nix` compiler that routes secrets based on declarative hardware `tags` (e.g., `sudhalaptoptpm`), allowing targeted re-keying via a custom `agenix-tag` flake app.
2. **Application Environments (sops-nix):** Used for service-level credentials (e.g., ERPNext `.env` files, Cloudflared tunnel tokens). Decryption is bound to the server's specific hardware SSH host key.

## Zero-Touch Provisioning (Bootstrapping)

Systems can be provisioned from bare-metal to a fully encrypted, fully configured state using a single command sequence via `disko`.

**1. Boot from a NixOS Live USB and elevate to root:**

```bash
sudo -i

```

**2. Partition, encrypt, and format the drive natively from GitHub:**

```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko github:your-username/nixos-dendritic#<target-host>

```

**3. Install the OS:**

```bash
nixos-install --flake github:your-username/nixos-dendritic#<target-host>

```

## Daily Operations

**Rebuild the local system:**

```bash
sudo nixos-rebuild switch --flake .#<target-host>

```

**Deploy remotely to the server:**

```bash
nixos-rebuild switch --flake .#server --target-host sudha@server --use-remote-sudo

```

**Update User Space (Home Manager):**

```bash
home-manager switch --flake .#<user>@<target-host>

```

**Rekey Secrets after adding a new hardware identity:**

```bash
nix run .#agenix-tag -- <tag-name> # Targeted rekey
# or 
nix run github:ryantm/agenix -- --rekey # Global rekey

```