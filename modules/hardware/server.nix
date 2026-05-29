{ inputs, lib, ... }:
{
  flake.nixosModules.server = { pkgs, config, modulesPath,... }: {

    imports = [ 
      inputs.disko.nixosModules.disko
      (modulesPath + "/installer/scan/not-detected.nix") 
    ];
    
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    networking = {
      networkmanager.enable = true;
      hostName = "server";
    };
    
    boot = {
  
      initrd.systemd.enable = true;      
      binfmt.emulatedSystems = [ "aarch64-linux" ];
      kernelPackages = pkgs.linuxPackages_latest;
      loader.grub = {
        enable = true;
        efiSupport = false; 
      };
      initrd.availableKernelModules = [ 
        "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod"
      ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];
    };

    hardware = {

      cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  
    };


    # 1. DISKO LAYOUT (1GB EFI + LUKS Encrypted EXT4)
    disko.devices = {
      disk = {
        main = {
          device = lib.mkDefault "/dev/sda"; 
          type = "disk";
          content = {
            type = "gpt"; # <-- Back to modern GPT
            partitions = {
              boot = {
                size = "1M";
                type = "EF02"; # GRUB core goes here
              };
              root = {
                size = "100%";
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
}