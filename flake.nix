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

      myPackageNames = builtins.attrNames (myOverlay pkgs pkgs);

    in
    {
      overlays.default = myOverlay;

      packages.${system} = pkgs.lib.getAttrs myPackageNames pkgs // {
        default = pkgs.runCommand "all-my-packages" {
          buildInputs = builtins.attrValues (pkgs.lib.getAttrs myPackageNames pkgs);
        } ''
          mkdir -p $out
          for i in $buildInputs; do
            cp -r $i/* $out/ || true
          done
        '';
      };
    };
}
