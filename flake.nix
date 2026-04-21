{
  description = "Paquets personnels de Philippe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland/v0.54.3";
  };

  outputs = { self, nixpkgs, hyprland }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;

      # Create base nixpkgs with hyprland overlay
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          hyprland.overlays.hyprland-packages
          (final: prev:
            let
              # callPackage for our custom packages
              callPackage = prev.lib.callPackageWith prev;

              # Build our custom packages
              packageDirs = builtins.readDir ./pkgs;
              onlyDirs = prev.lib.filterAttrs (name: type: type == "directory") packageDirs;

              # Build packages in stages to handle dependencies
              # First build jdk26 (needed by motivewave)
              jdk26 = callPackage ./pkgs/jdk26 { };

              # Then build other packages (except motivewave)
              packagesWithoutMotivewave = prev.lib.filterAttrs (name: type: name != "motivewave" && type == "directory") packageDirs;
              packagesWithout = builtins.mapAttrs
                (name: type: callPackage (./pkgs + "/${name}") { })
                packagesWithoutMotivewave;

            in
              # Finally build motivewave with jdk26 passed explicitly
              packagesWithout // {
                motivewave = callPackage ./pkgs/motivewave {
                  pkgsUnstable = prev;
                  jdk26 = jdk26;
                };
              }
          )
        ];
        config.allowUnfree = true;
      };

    in
    {
      overlays.default = final: prev: {
        # Expose our custom packages (hyprland uses patched aquamarine)
        inherit (pkgs)
          hyprland hyprspace
          jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave;
      };

      packages.${system} = {
        inherit (pkgs)
          hyprland hyprspace
          jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave;

        default = pkgs.buildEnv {
          name = "all-my-packages";
          paths = with pkgs; [
            hyprland hyprspace
            jdk26 plasma-panel-colorizer plasma-window-title-applet krohnkite motivewave
          ];
        };
      };
    };
}
