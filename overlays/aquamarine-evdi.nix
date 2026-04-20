# Overlay to patch aquamarine for EVDI/DisplayLink compatibility
final: prev: {
  aquamarine = prev.aquamarine.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./aquamarine-evdi.patch ];
  });
}
