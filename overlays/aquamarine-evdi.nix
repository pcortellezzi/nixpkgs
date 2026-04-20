# Overlay to patch aquamarine for EVDI/DisplayLink compatibility with Hyprland
# This forces EVDI connectors to be detected
final: prev: {
  aquamarine = prev.aquamarine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./aquamarine-evdi.patch ];
  });
}
