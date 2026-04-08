{ pkgsUnstable }:

final: prev:

let
  # Build jdk26 first — it has no dependency on other custom packages
  jdk26 = prev.callPackage ./pkgs/jdk26 { };

  # callPackage with jdk26 and pkgsUnstable available for other packages
  callPackage = prev.lib.callPackageWith (prev // { inherit pkgsUnstable jdk26; });

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
