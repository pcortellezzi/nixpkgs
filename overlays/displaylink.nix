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

      # Copier les fichiers de la librairie
      mkdir -p $out/lib/displaylink
      cp -r opt/displaylink/* $out/lib/displaylink/

      # Créer un lien symbolique pour l'exécutable principal
      mkdir -p $out/bin
      ln -s $out/lib/displaylink/DisplayLinkManager $out/bin/DisplayLinkManager

      # Copier et corriger le fichier de service systemd
      mkdir -p $out/lib/systemd/system
      sed "s|/opt/displaylink/DisplayLinkManager|$out/bin/DisplayLinkManager|" \
        lib/systemd/system/displaylink-driver.service > $out/lib/systemd/system/displaylink-driver.service

      # Copier les règles udev
      mkdir -p $out/lib/udev/rules.d
      cp -r lib/udev/rules.d/* $out/lib/udev/rules.d/

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
