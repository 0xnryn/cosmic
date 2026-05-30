# ~/nixos-dendritic/secrets.nix
let
  # Evaluate the local flake dynamically
  flake = builtins.getFlake (builtins.toString ./.);
in
# Extract the compiled rules from the flake's output object
flake.outputs.agenixSecrets