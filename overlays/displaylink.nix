final: prev: {
  # Surcharge la fonction displaylink pour utiliser notre version locale.
  displaylink = prev.displaylink.overrideAttrs (oldAttrs: {
    version = "6.2.0-30";
    src = prev.fetchurl {
      url = "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip";
      hash = "sha256-JQO7eEz4pdoPkhcn9tIuy5R4KyfsCniuw6eXw/rLaYE=";
    };
    evdi = final.linuxPackages.evdi;
  });
}
