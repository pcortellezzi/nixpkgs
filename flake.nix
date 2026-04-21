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
              customPackages = builtins.mapAttrs
                (name: type: callPackage (./pkgs + "/${name}") { })
                onlyDirs;
                
            in
              customPackages
          )
        ];
        config.allowUnfree = true;
      };

    in
    {
      overlays.default = final: prev: {
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
