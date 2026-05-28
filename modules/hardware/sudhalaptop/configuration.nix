{ ... }:
{
  flake.nixosModules.sudhalaptop = { pkgs, config, inputs, ... }: {
    

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
  };
}