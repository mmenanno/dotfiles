{ pkgs, ... }:

let
  customFonts = pkgs.stdenv.mkDerivation {
    name = "custom-fonts";
    # Optional: Place custom .ttf/.otf fonts in nix/files/fonts/
    # If the directory is empty or missing, only nerd-fonts.meslo-lg is installed
    src = ../../files/fonts;
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      mkdir -p $out/share/fonts/opentype

      # Copy font files from source
      cp $src/*.ttf $out/share/fonts/truetype/ 2>/dev/null || true
      cp $src/*.otf $out/share/fonts/opentype/ 2>/dev/null || true
    '';
  };
in {
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    customFonts
  ];
}
