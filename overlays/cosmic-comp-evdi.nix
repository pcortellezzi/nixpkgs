# Override cosmic-comp with a patched version that uses the primary GPU's
# allocator for software outputs (EVDI/DisplayLink), following the pattern
# from smithay's anvil (PR #1680 "Primary render fallback").
# Remove this overlay once the fix is upstreamed or no longer needed.
final: prev:
let
  src = prev.fetchFromGitHub {
    owner = "pcortellezzi";
    repo = "cosmic-comp";
    rev = "befa8b9aeaefa45fbca503e5eefe9b1dfed54115";
    hash = "sha256-pHIw8dlT/nIEhLS6bJwxRMDdq0pHSazOG17UPuSDwPA=";
  };
in
{
  cosmic-comp = prev.cosmic-comp.overrideAttrs (old: {
    version = "1.0-master-evdi-primary-gpu-fallback";
    inherit src;

    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "cosmic-comp-1.0-master-evdi-primary-gpu-fallback-vendor";
      hash = "sha256-MI8cJzjZd2UeWBESu8xEDYQv0Oa4PRhc4pOCN0zDNO4=";
      # Workaround: nix-prefetch-git binary has a version suffix
      # (nix-prefetch-git-26.05pre-git) but fetch-cargo-vendor-util
      # expects "nix-prefetch-git". Add a wrapper with the expected name.
      nativeBuildInputs = [
        (prev.writeShellScriptBin "nix-prefetch-git" ''
          exec "${prev.nix-prefetch-git}/bin/"nix-prefetch-git-* "$@"
        '')
      ];
    };
  });
}
