{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

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
      
      packages.${system} = 
        let
          # Liste des noms de dossiers dans ./pkgs
          pkgsNames = builtins.attrNames (
            lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./pkgs)
          );
          
          # Création d'un set { name = pkgs.${name}; } pour chaque paquet
          myCustomPkgs = lib.genAttrs pkgsNames (name: pkgs.${name});
        in
        myCustomPkgs // {
          default = pkgs.buildEnv {
            name = "all-my-packages";
            paths = builtins.attrValues myCustomPkgs;
          };
        };
    };
}
