{ inputs, lib, ... }:
{
  flake.nixosModules.laptop = { pkgs, config, modulesPath,... }: {
    boot = {
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };

    hardware.bluetooth.enable = true;

    networking = {
      networkmanager.enable = true;
      firewall.enable = false;
      hostName = "laptop";
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
  
    # 2. CORE HARDWARE DRIVERS
    imports = [ 
      inputs.disko.nixosModules.disko
      (modulesPath + "/installer/scan/not-detected.nix") 
    ];
  
    boot.initrd.availableKernelModules = [ 
      "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" 
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.extraModulePackages = [ ];
  
    # 3. PLATFORM IDENTITY
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;


    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    boot.kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
    ];

    # Load drivers for both AMD iGPU and NVIDIA dGPU
    services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];

    hardware.nvidia = {
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
}