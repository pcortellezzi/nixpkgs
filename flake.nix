{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      myOverlay = import ./overlay.nix;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ myOverlay ];
        config.allowUnfree = true;
      };
      myPackages = (import ./overlay.nix) pkgs pkgs;

      # List of packages to include in the default build
      defaultPackages = [
        pkgs.displaylink
        pkgs.motivewave
        pkgs.motivewave-beta
        pkgs.linuxPackages.evdi
      ];
    in
    {
      overlays.default = myOverlay;
      packages.${system} = myPackages // {
        default = pkgs.runCommand "all-my-packages" {
          buildInputs = defaultPackages;
        } ''
          mkdir -p $out
          for i in $buildInputs; do
            cp -r $i/* $out/ || true
          done
        '';
      };
    };
}
