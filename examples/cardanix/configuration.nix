{
  inputs,
  system,
  ...
}: {
  imports = [
    inputs.cymenixos.nixosModules.${system}.default
    ./os.nix
    ./home.nix
  ];
}
