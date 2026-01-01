{ pkgsUnstable }:

final: prev:

let
  # On crée un scope étendu qui contient nos dépendances spéciales
  # callPackage piochera dedans automatiquement selon les besoins du paquet
  callPackage = prev.lib.callPackageWith (prev // { inherit pkgsUnstable; });

  packageDirs = builtins.readDir ./pkgs;
  onlyDirs = prev.lib.filterAttrs (name: type: type == "directory") packageDirs;

  # On génère tous les paquets du dossier ./pkgs
  packages = builtins.mapAttrs
    (name: type: callPackage (./pkgs + "/${name}") { })
    onlyDirs;

  # Import de tous les fichiers .nix du dossier ./overlays
  customOverlays = prev.lib.attrValues (
    prev.lib.mapAttrs (
      name: type:
        if type == "regular" && prev.lib.hasSuffix ".nix" name
        then import (./overlays + "/${name}")
        else null
    ) (builtins.readDir ./overlays)
  );

in
  # On fusionne nos paquets et les résultats des overlays personnalisés
  prev.lib.foldl (acc: overlay: prev.lib.recursiveUpdate acc (overlay final prev)) packages customOverlays