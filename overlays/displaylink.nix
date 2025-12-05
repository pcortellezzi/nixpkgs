final: prev: {
  displaylink = prev.displaylink.overrideAttrs (oldAttrs: {
    src = pre.fetchurl {
      url = "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/non-free/amd64/displaylink-driver-6.2.0-30_amd64.deb";
      hash = "sha256-AWnFc6h4bD9PA3PvE3oPRMoWuBb6kEFE8q7SEgBvPMU=";
    };
  });
}
