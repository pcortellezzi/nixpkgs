final: prev: {
  displaylink = final.stdenv.mkDerivation rec {
    pname = "displaylink";
    # Les valeurs ci-dessous sont des placeholders.
    # Le workflow d'automatisation les remplacera par les bonnes valeurs.
    version = "0.0.0";

    src = final.fetchurl {
      url = "https://example.com/placeholder.deb";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
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
