# AGENTS.md — my-nixpkgs

> Guide de référence pour les agents IA travaillant sur les paquets Nix personnalisés de Philippe. Ce dépôt est le fournisseur de paquets pour [nixos-config](https://github.com/pcortellezzi/nixos-config).

---

## Vue d'ensemble

```
┌────────────────────────────────────────────────────────────┐
│  my-nixpkgs                                                │
│  github:pcortellezzi/nixpkgs                              │
│                                                            │
│  Rôle : paquets custom + overlays de patching             │
│  CI : push main → build → Cachix → lock update config     │
└───────────────────────────┬────────────────────────────────┘
                            │ flake input + overlay
                            ▼
┌────────────────────────────────────────────────────────────┐
│  nixos-config                                              │
│  Consomme via nixpkgs.overlays = [ my-nixpkgs.overlays.default ] │
└────────────────────────────────────────────────────────────┘
```

## Structure du dépôt

```
nixpkgs/
├── flake.nix              # Overlay composé + 8 paquets + build CI global
├── flake.lock             # Inputs : nixpkgs, hyprland
├── overlays/
│   ├── aquamarine-evdi.nix   # Patch aquamarine pour compatibilité EVDI/DisplayLink
│   ├── displaylink.nix       # Override URL source du driver DisplayLink
│   └── cosmic-comp-evdi.nix  # Patch cosmic-comp pour EVDI (non utilisé dans l'overlay)
└── pkgs/
    ├── aquamarine/          # (répertoire vide — fourni par hyprland overlay)
    ├── hyprland/            # (répertoire vide — fourni par hyprland overlay)
    ├── hyprspace/           # Plugin Hyprland workspace overview
    ├── jdk26/               # Adoptium Temurin JDK 26 (binaires précompilés)
    ├── krohnkite/           # KWin dynamic tiling
    ├── motivewave/          # Plateforme de trading (depuis .deb)
    ├── opencode-voice-models/ # Modèles voix whisper+piper (pré-téléchargés)
    ├── plasma-panel-colorizer/ # Plasma 6 panel colorizer plasmoid
    ├── plasma-window-title-applet/ # Plasma 6 window title plasmoid
    └── tealstreet/          # Terminal crypto trading (AppImage)
```

## L'overlay composé (cœur du dépôt)

L'overlay `default` (dans `flake.nix`) est **la seule chose que nixos-config consomme**. Il est composé de 4 couches empilées via une fonction `compose` (foldl) :

```
Couche 1: hyprland.overlays.hyprland-packages
    → fournit hyprland, aquamarine (upstream)
    ↓
Couche 2: aquamarine-evdi.nix
    → patch C++ d'aquamarine pour les devices EVDI/DisplayLink
    ↓
Couche 3: displaylink.nix
    → override l'URL source du driver DisplayLink (version Synaptics)
    ↓
Couche 4: customPkgsOverlay
    → injecte les 8 paquets locaux
    → force hyprland à utiliser l'aquamarine patché
    → force hyprspace à utiliser hyprland + aquamarine patchés
```

**Règle absolue :** ne jamais réordonner ces couches. Chacune dépend de la précédente.

### Pourquoi des répertoires `pkgs/aquamarine/` et `pkgs/hyprland/` vides ?

Ces paquets sont fournis par l'overlay Hyprland upstream (couche 1). Les répertoires vides sont des artéfacts — ils n'ont pas d'effet fonctionnel. Ne pas les supprimer sans vérifier qu'aucun code n'y fait référence.

---

## Catalogue des paquets

| Paquet | Type de dérivation | Source | Auto-update CI |
|--------|-------------------|--------|----------------|
| `jdk26` | `stdenv.mkDerivation` + autoPatchelf | GitHub Adoptium releases (binaires) | Non |
| `motivewave` | `stdenv.mkDerivation` + dpkg | motivewave.com (.deb) | Oui (daily) |
| `tealstreet` | `appimageTools.wrapType2` | GitHub releases (AppImage) | Non |
| `hyprspace` | `stdenv.mkDerivation` | GitHub (fork pcortellezzi) | Non |
| `opencode-voice-models` | `stdenvNoCC.mkDerivation` | HuggingFace (3 fichiers) | Non |
| `krohnkite` | `stdenv.mkDerivation` + kpackagetool6 | Codeberg releases (.kwinscript) | Non |
| `plasma-panel-colorizer` | `stdenv.mkDerivation` | GitHub releases (plasmoid) | Non |
| `plasma-window-title-applet` | `stdenv.mkDerivation` | GitHub (commit pin) | Non |

### Particularités par paquet

- **`jdk26`** : Utilise `autoPatchelfHook` pour les binaires précompilés Adoptium. `dontStrip = true` car ce sont des binaires non strippables.
- **`motivewave`** : Accepte un paramètre optionnel `licenseFile` (passé depuis home-manager dans nixos-config). Le `.deb` est extrait avec `dpkg-deb`. Les dépendances ffmpeg manquantes sont listées dans `autoPatchelfIgnoreMissingDeps`.
- **`tealstreet`** : AppImage de type 2 wrappé avec flags Wayland/Ozone forcés. Renomme le binaire wrappé et injecte un script wrapper pour passer `--ozone-platform-hint=auto`.
- **`hyprspace`** : Compilé depuis les sources, patch le Makefile pour les chemins d'include hyprland. Dépend de `hyprland` et `aquamarine` patchés via l'overlay.
- **`opencode-voice-models`** : Télécharge 3 fichiers (whisper model + 2 piper voice files) et les place dans `$out/share/opencode-voice/`.
- **`krohnkite`** : Utilise `kpackagetool6` pour installer le script KWin. Le format `.kwinscript` n'est pas décompressé (`dontUnpack = true`).
- **`plasma-panel-colorizer`** : Simple copie de fichiers dans `$out/share/plasma/plasmoids/`.
- **`plasma-window-title-applet`** : Idem, copie de `metadata.json` + `contents/`.

---

## CI/CD

### Chaîne complète

```
push main
  → nix-cache.yml
    → nix build .#  (tous les paquets, via buildEnv)
    → push to pcortellezzi.cachix.org
  → trigger-nixos-update.yml (si nix-cache OK)
    → clone nixos-config
    → nix flake lock --update-input my-nixpkgs
    → commit + push flake.lock
      → (nixos-config CI déploie automatiquement)
```

### Détail des workflows

| Workflow | Déclencheur | Ce qu'il fait |
|----------|-------------|---------------|
| `nix-cache.yml` | push main (ignore `.github/`, `.gitignore`) | `nix build .#` → `cachix push pcortellezzi` |
| `trigger-nixos-update.yml` | `nix-cache.yml` complété avec succès | Clone nixos-config → `nix flake lock --update-input my-nixpkgs` → commit+push |
| `update-motivewave.yml` | Tous les jours à 10:00 + manuel | Vérifie si MotiveWave a une nouvelle version → met à jour hash+version → commit+push |
| `update-displaylink.yml` | Tous les jours à 09:00 + manuel | Récupère la dernière version DisplayLink depuis nixpkgs upstream → met à jour l'overlay → commit+push |

### Secrets GitHub Actions requis

| Secret | Usage |
|--------|-------|
| `CACHIX_AUTH_TOKEN` | Authentification pour pousser vers le cache `pcortellezzi` |
| `PAT` | Accès GitHub pour cloner et pusher vers nixos-config |

---

## Guides par use case

### Ajouter un nouveau paquet

1. Créer `pkgs/<nom>/default.nix` :
   ```nix
   { lib, stdenv, fetchFromGitHub }:

   stdenv.mkDerivation rec {
     pname = "<nom>";
     version = "1.0.0";

     src = fetchFromGitHub {
       owner = "<owner>";
       repo = "<repo>";
       rev = "v${version}";
       hash = "";  # laisser vide, nix-build donnera le hash
     };

     installPhase = ''
       mkdir -p $out/bin
       cp <binaire> $out/bin/
     '';

     meta = with lib; {
       description = "...";
       homepage = "...";
       license = licenses.mit;
       platforms = platforms.linux;
     };
   }
   ```

2. Builder pour obtenir le hash :
   ```bash
   nix build .#<nom>  # échoue mais affiche le hash attendu
   # Copier le hash dans pkgs/<nom>/default.nix
   nix build .#<nom>  # re-builder, cette fois avec succès
   ```

3. Enregistrer dans `flake.nix` → `customPkgsOverlay` :
   ```nix
   customPkgsOverlay = f: p:
     let
       callPackage = f.lib.callPackageWith f;
       # ... existants ...
       <nom> = callPackage ./pkgs/<nom> { };
     in {
       inherit <nom>;
       # ... existants ...
     };
   ```

4. Ajouter dans `flake.nix` → `outputs.packages.${system}` :
   ```nix
   packages.${system} = {
     inherit (pkgs) <nom> ...;
     default = pkgs.buildEnv {
       paths = with pkgs; [ <nom> ... ];
     };
   };
   ```

5. Vérifier que `nix build .#` (le build global) passe.

6. Si le paquet a besoin d'une mise à jour automatique, ajouter un workflow GitHub Actions (prendre `update-motivewave.yml` comme modèle).

### Modifier un paquet existant

1. Éditer `pkgs/<nom>/default.nix`
2. Builder : `nix build .#<nom>`
3. Si le hash change, `nix flake lock --update-input nixpkgs` n'est pas nécessaire — le paquet est local
4. Builder tout pour vérifier la non-régression : `nix build .#`

### Mettre à jour un paquet (version bump)

1. Modifier `version` et `hash`/`sha256` dans le `default.nix`
2. Builder : `nix build .#<nom>`
3. Builder tout : `nix build .#`

### Ajouter un overlay de patching

1. Créer `overlays/<nom>.nix` avec la signature standard :
   ```nix
   final: prev: {
     <paquet> = prev.<paquet>.overrideAttrs (old: {
       # modifications
     });
   }
   ```

2. L'importer dans la liste `compose` de `defaultOverlay` dans `flake.nix`. **Choisir soigneusement la position** dans l'ordre d'empilement (avant ou après `customPkgsOverlay` selon les dépendances).

### Builder et tester localement

```bash
# Builder un paquet spécifique
nix build .#jdk26
nix build .#motivewave

# Builder tous les paquets (buildEnv)
nix build .#

# Vérifier la sortie
ls -la result/
```

---

## Conventions à respecter

- **Pas de `rec` dans `mkDerivation`** sauf si `version` est utilisée dans `src.url` (ex: `tealstreet`)
- **Toujours utiliser `callPackage`** dans l'overlay — ça résout automatiquement les dépendances
- **`autoPatchelfHook`** pour les binaires précompilés (jdk26)
- **`dontUnpack = true`** pour les fichiers qui ne sont pas des archives (.kwinscript, modèles pré-téléchargés)
- **Toujours builder `nix build .#` avant de push** — ça build tout et c'est ce que fait la CI
- **Ne pas modifier `flake.lock` manuellement** — utiliser `nix flake lock --update-input <input>`
- **L'ordre des overlays est critique** — ne pas réordonner sans comprendre les dépendances
- **`pkgs/aquamarine/` et `pkgs/hyprland/` sont des répertoires vides intentionnels** — ne pas les supprimer

## Relation avec nixos-config

Tout push sur `main` de ce dépôt déclenche automatiquement :
1. Build + push Cachix
2. Mise à jour du `flake.lock` de nixos-config (via `nix flake lock --update-input my-nixpkgs`)
3. Déploiement automatique sur les 3 machines (via le CI de nixos-config)

**Ne jamais pusher directement une modification de `flake.lock` dans nixos-config** pour mettre à jour my-nixpkgs — laisser la CI le faire. Si besoin urgent de forcer la mise à jour, utiliser `nix flake lock --update-input my-nixpkgs` dans nixos-config et committer.
