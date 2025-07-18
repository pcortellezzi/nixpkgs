{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default = final: prev: {
        motivewave-beta = prev.callPackage ./pkgs/motivewave-beta {};
      };

      packages.${system} = {
        inherit (pkgs) motivewave-beta;
      };
    };
}