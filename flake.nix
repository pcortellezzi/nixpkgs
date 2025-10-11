{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      system = "x86_64-linux";

      pkgsUnstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import ./overlay.nix { inherit pkgsUnstable; }) ];
        config.allowUnfree = true;
      };

    in
    {
      overlays.default = import ./overlay.nix { inherit pkgsUnstable; };
      packages.${system} = {
        displaylink = pkgs.displaylink;
        motivewave = pkgs.motivewave;
        motivewave-beta = pkgs.motivewave-beta;
        evdi = pkgs.linuxPackages_latest.evdi;
        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = [
            pkgs.displaylink
            pkgs.motivewave
            pkgs.motivewave-beta
            pkgs.linuxPackages_latest.evdi
          ];
        };
      };
    };
}
