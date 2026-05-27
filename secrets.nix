let
  sudha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/N5EHrKFPyXEgKpx5ew6yDnKbPXFkdTmy2hQoV/v8d"; 

  # lenovoideapadgaming3_tpm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI...";

  allKeys = [ sudha ];
in
{
  "secrets/sshsudha.age".publicKeys = allKeys;
  "secrets/rootuserpass.age".publicKeys = allKeys;
  "secrets/sudhauserpass.age".publicKeys = allKeys;
}