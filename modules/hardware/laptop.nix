{ inputs, lib, ... }:
{
  flake.nixosModules.laptop = { pkgs, config, modulesPath,... }: {

    imports = [ 
      inputs.disko.nixosModules.disko
      inputs.lanzaboote.nixosModules.lanzaboote # Inject Secure Boot framework
      (modulesPath + "/installer/scan/not-detected.nix") 
    ];
    
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    networking = {
      networkmanager.enable = true;
      hostName = "laptop";
    };
    
    boot = {
      initrd.systemd.enable = true;      
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
  
      # NATIVE TPM LUKS BINDING
      # Crucial: We bind strictly to pcr7 (Secure Boot certificate validation).
      # This prevents any NVIDIA module updates from breaking the automated unlock flow.
      initrd.luks.devices."enc".crypttabExtraOpts = [ 
        "tpm2-device=auto"
        "tpm2-pcrs=7" 
      ];
  
      # Standard systemd-boot must be turned OFF for lanzaboote to manage the EFI stub
      loader.systemd-boot.enable = lib.mkForce false;
      loader.efi.canTouchEfiVariables = true;
  
      # LANZABOOTE SECURE BOOT
      # LANZABOOTE V1.0.0 STANDARD CONFIGURATION
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
        autoGenerateKeys.enable = true; 
        autoEnrollKeys = {
          enable = true;
        };
      };
  
      kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
      ];
  
      initrd.availableKernelModules = [ 
        "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" "tpm_crb" "tpm_tis" 
      ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-amd" ];
      extraModulePackages = [ ];
    };

    services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

    hardware = {

      bluetooth.enable = true;

      cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      
      nvidia = {
        modesetting.enable = true;
        open = true;
        powerManagement.enable = true;
        powerManagement.finegrained = true;
        dynamicBoost.enable = true;
        nvidiaSettings = true;
        
        # We have access to 'config' here because of the lambda signature above
        package = config.boot.kernelPackages.nvidiaPackages.beta;

        prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;
          amdgpuBusId = "PCI:5:0:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };


    # 1. DISKO LAYOUT (1GB EFI + LUKS Encrypted EXT4)
    disko.devices = {
      disk = {
        main = {
          # Change this to match your actual disk path (e.g., /dev/sda or /dev/nvme0n1)
          device = lib.mkDefault "/dev/nvme0n1"; 
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "enc"; # The mapped name in /dev/mapper/crypted
                  settings = {
                    allowDiscards = true; # Crucial for NVMe SSD health (TRIM)
                  };
                  # The actual filesystem inside the LUKS container
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}