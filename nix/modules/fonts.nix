{ pkgs, ... }: 

let
  customFonts = pkgs.stdenv.mkDerivation {
    name = "custom-fonts";
    src = ../files/fonts;
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
