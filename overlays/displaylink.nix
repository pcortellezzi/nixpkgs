final: prev: {
  displaylink = final.stdenv.mkDerivation rec {
    pname = "displaylink";
    # Les valeurs ci-dessous sont des placeholders.
    # Le workflow d'automatisation les remplacera par les bonnes valeurs.
    version = "6.2.0-30";

    src = final.fetchurl {
      url = "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/non-free/amd64/displaylink-driver-6.2.0-30_amd64.deb";
      hash = "sha256-AWnFc6h4bD9PA3PvE3oPRMoWuBb6kEFE8q7SEgBvPMU=";
    };

    nativeBuildInputs = [ final.autoPatchelfHook final.dpkg ];

    buildInputs = [ final.libuuid final.libusb1 final.stdenv.cc.cc.lib ];

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      # La structure interne du .deb peut varier, ceci est une estimation
      # Copier le contenu principal
      mkdir -p $out/lib/displaylink
      # Le dossier opt/displaylink n'existe peut-être pas, ignorer l'erreur si c'est le cas
      cp -r opt/displaylink/* $out/lib/displaylink/ 2>/dev/null || true

      # Copier le service systemd
      mkdir -p $out/lib/systemd/system
      cp -r lib/systemd/system/* $out/lib/systemd/system/

      # autoPatchelfHook s'occupe de corriger les binaires
      runHook postInstall
    '';

    # Lier la dépendance evdi
    evdi = final.linuxPackages.evdi;

    meta = with final.lib; {
      description = "Userspace driver for DisplayLink USB graphics adapters";
      homepage = "https://www.synaptics.com/products/displaylink-graphics";
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      license = licenses.unfree;
      maintainers = with maintainers; [ amol ]; # Pris de la dérivation nixpkgs originale
      platforms = [ "x86_64-linux" ];
    };
  };
}
