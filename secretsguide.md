nix-shell -p phraze --run "phraze -w 6 -n 10 -s ' ' -l m"

ssh-keygen -t ed25519 -C "root" -f secrets/root/root

ssh-agent bash -c 'ssh-add secrets/root && nix shell github:ryantm/agenix --command agenix --rekey'

ssh-agent bash -c 'ssh-add secrets/root && nix run .#agenixrekey -- root'

nix run nixpkgs#mkpasswd -- -m sha-512

ssh-keygen -t ed25519 -C "name" -f secrets/name

ssh-agent bash -c 'ssh-add secrets/root/ && nix shell github:ryantm/agenix --command agenix -e secrets/new_secret_name.age'


sudo age-plugin-tpm --generate -o /etc/laptoptpm



sudo chmod 600 /etc/laptoptpm
sudo chown root:root /etc/laptoptpm

sudo nix run nixpkgs#sbctl -- status

sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2

sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 --tpm2-with-pin=yes /dev/nvme0n1p2