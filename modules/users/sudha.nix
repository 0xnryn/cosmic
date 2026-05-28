{ inputs, lib, config, builtins, ... }:
{

  flake.nixosModules.sudha = { config, pkgs, lib, ... }: {
    
    age.secrets."sudhauserpass" = {
      file = ../../secrets/sudhauserpass.age;
    };
    
    users.users.sudha = {
      isNormalUser = true;
      extraGroups = [ "wheel" "dialout" "docker" ];
      hashedPasswordFile = config.age.secrets."sudhauserpass".path;
    };

    age.secrets."sshsudha" = {
      file = ../../secrets/sshsudha.age;
      mode = "0600";
      owner = "sudha";
    };
  };
}
