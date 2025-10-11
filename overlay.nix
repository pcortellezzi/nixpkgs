{ pkgsUnstable }:

final: prev:

let
  specialArgs = {
    motivewave = { inherit pkgsUnstable; };
  };

  packageDirs = builtins.readDir ./pkgs;

  onlyDirs = prev.lib.filterAttrs (name: type: type == "directory") packageDirs;

  packages = builtins.mapAttrs
    (
      name: type:
        let
          args = specialArgs."${name}" or { };
        in
          prev.callPackage (./pkgs + "/${name}") args
    )
    onlyDirs;

  # Import all overlays from the overlays/ directory
  customOverlays = prev.lib.attrValues (
    prev.lib.mapAttrs (
      name: type:
        if type == "regular" && prev.lib.hasSuffix ".nix" name
        then import (./overlays + "/${name}")
        else null
    ) (builtins.readDir ./overlays)
  );

in

  prev.lib.foldl (acc: overlay: prev.lib.recursiveUpdate acc (overlay final prev)) packages customOverlays
