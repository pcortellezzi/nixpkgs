final: prev:

let
  packageDirs = builtins.readDir ./pkgs;

  onlyDirs = prev.lib.filterAttrs (name: type: type == "directory") packageDirs;

  packages = builtins.mapAttrs
    (
      name: type:
        prev.callPackage (./pkgs + "/${name}") { }
    )
    onlyDirs;
in

packages
