{ pkgsUnstable, hyprland }:

final: prev:

let
  # Build jdk26 first — it has no dependency on other custom packages
  jdk26 = prev.callPackage ./pkgs/jdk26 { };

  # Hyprland 0.54.3 and its dependencies from flake input
  hyprland-0_54_3 = hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland;
  hyprland-unwrapped = hyprland.packages.${prev.stdenv.hostPlatform.system}.hyprland-unwrapped;
  
  # Extract specific dependencies from hyprland's build inputs
  hyprland-deps = builtins.listToAttrs (map (dep: { 
    name = dep.pname or (builtins.parseDrvName dep.name).name; 
    value = dep; 
  }) (hyprland-unwrapped.buildInputs or []));
  
  # Get specific dependencies we need for plugins
  aquamarine = hyprland-deps.aquamarine or prev.aquamarine;
  hyprlang = hyprland-deps.hyprlang or prev.hyprlang;
  hyprutils = hyprland-deps.hyprutils or prev.hyprutils;
  hyprgraphics = hyprland-deps.hyprgraphics or prev.hyprgraphics;
  hyprcursor = hyprland-deps.hyprcursor or prev.hyprcursor;
  libdrm = hyprland-deps.libdrm or prev.libdrm;
  hyprland-protocols = hyprland-deps.hyprland-protocols or prev.hyprland-protocols;
  wayland-protocols = hyprland-deps.wayland-protocols or prev.wayland-protocols;

  # callPackage with hyprland and its deps available for other packages
  callPackage = prev.lib.callPackageWith (prev // { inherit pkgsUnstable jdk26 hyprland-0_54_3 aquamarine hyprlang hyprutils hyprgraphics hyprcursor libdrm hyprland-protocols wayland-protocols; });

  packageDirs = builtins.readDir ./pkgs;
  onlyDirs = prev.lib.filterAttrs (name: type: type == "directory") packageDirs;

  # On génère tous les paquets du dossier ./pkgs
  packages = builtins.mapAttrs
    (name: type: callPackage (./pkgs + "/${name}") { })
    onlyDirs;

  # Import de tous les fichiers .nix du dossier ./overlays
  customOverlays = prev.lib.filter (x: x != null) (prev.lib.attrValues (
    prev.lib.mapAttrs (
      name: type:
        if type == "regular" && prev.lib.hasSuffix ".nix" name
        then import (./overlays + "/${name}")
        else null
    ) (builtins.readDir ./overlays)
  ));

in
  # On fusionne nos paquets et les résultats des overlays personnalisés
  prev.lib.foldl (acc: overlay: prev.lib.recursiveUpdate acc (overlay final prev)) packages customOverlays
