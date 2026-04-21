# Overlay to patch aquamarine for EVDI/DisplayLink compatibility
# This overlay should be applied AFTER the hyprland overlay if present
final: prev: {
  # Patch aquamarine if it exists (from hyprland overlay or nixpkgs)
  aquamarine = (prev.aquamarine or prev.aquamarine_0_10 or prev.aquamarine_0_9).overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./aquamarine-evdi.patch ];
  });
}
