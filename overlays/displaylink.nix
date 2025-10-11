final: prev: {
  displaylink = final.stdenv.mkDerivation rec {
    pname = "displaylink";
    version = "6.2.0-30";

    src = final.fetchurl {
      url = "https://www.synaptics.com/sites/default/files/Ubuntu/pool/stable/non-free/amd64/displaylink-driver-6.2.0-30_amd64.deb";
      hash = "sha256-AWnFc6h4bD9PA3PvE3oPRMoWuBb6kEFE8q7SEgBvPMU=";
    };

    nativeBuildInputs = [ final.dpkg final.makeWrapper ];

    buildInputs = [
      final.libuuid
      final.libusb1
      final.stdenv.cc.cc.lib
      final.linuxPackages.evdi
    ];

    libPath = final.lib.makeLibraryPath [
      final.stdenv.cc.cc.lib
      final.libuuid
      final.libusb1
      final.linuxPackages.evdi
    ];

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

      # Install the official Nixpkgs 99-displaylink.rules
      mkdir -p $out/lib/udev/rules.d
      echo 'ACTION=="add",SUBSYSTEM=="usb", DRIVERS=="usb", ATTRS{idVendor}=="17e9", ATTR{bInterfaceClass}=="ff", ATTR{bInterfaceProtocol}=="03", TAG+= "systemd", ENV{SYSTEMD_WANTS}="dlm.service"' > $out/lib/udev/rules.d/99-displaylink.rules

      # Apply patchelf and wrapProgram for DisplayLinkManager
      patchelf \
        --set-interpreter $(cat ${final.stdenv.cc}/nix-support/dynamic-linker) \
        --set-rpath ${libPath} \
        $out/bin/DisplayLinkManager
      wrapProgram $out/bin/DisplayLinkManager \
        --chdir "$out/lib/displaylink"

      runHook postInstall
    '';

    dontPatchELF = true;

    meta = with final.lib;
      {
        description = "Userspace driver for DisplayLink USB graphics adapters";
        homepage = "https://www.synaptics.com/products/displaylink-graphics";
        sourceProvenance = [ sourceTypes.binaryNativeCode ];
        license = licenses.unfree;
        maintainers = with maintainers; [ amol ]; # Pris de la dérivation nixpkgs originale
        platforms = [ "x86_64-linux" ];
      };
  };
}
