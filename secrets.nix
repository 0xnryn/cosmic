let
  # execute this command below after adding or removeing a public key
  # nix run github:ryantm/agenix -- --rekey
  sudha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/N5EHrKFPyXEgKpx5ew6yDnKbPXFkdTmy2hQoV/v8d"; 
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJQMz2mXavnOldYheOwKDpX5M9fRMOZ3Ib0N06PexkQh";
  allKeys = [ sudha laptop];
in
{
  "secrets/sshsudha.age".publicKeys = allKeys;
  "secrets/sudhauserpass.age".publicKeys = allKeys;
}