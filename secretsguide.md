nix-shell -p phraze --run "phraze -w 6 -n 10 -s ' ' -l m"

ssh-keygen -t ed25519 -C "root" -f secrets/root/root

ssh-agent bash -c 'ssh-add secrets/root && nix shell github:ryantm/agenix --command agenix --rekey'

ssh-agent bash -c 'ssh-add secrets/root && nix run .#agenixrekey -- root'

nix run nixpkgs#mkpasswd -- -m sha-512

ssh-keygen -t ed25519 -C "name" -f secrets/name

ssh-agent bash -c 'ssh-add secrets/root/ && nix shell github:ryantm/agenix --command agenix -e secrets/new_secret_name.age'



