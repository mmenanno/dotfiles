{ pkgs, ... }:

let
  autoclick = pkgs.stdenvNoCC.mkDerivation {
    pname = "autoclick";
    version = "2022-01-29";

    src = pkgs.fetchurl {
      url = "https://tars.mahdi.jp/apps/autoclick.zip";
      hash = "sha256-R7J5TVvhVBCcBmIA1aZjNTYUfKUIUBZFnwC6nGjcvBs=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r Autoclick.app $out/Applications/
    '';
  };
in
{
  system.activationScripts.postActivation.text = ''
    echo "Checking for AutoClick installation..."
    if [ ! -d "/Applications/Autoclick.app" ]; then
      echo -e "\033[0;34mAutoClick not found. Installing from Nix store...\033[0m"
      cp -r "${autoclick}/Applications/Autoclick.app" /Applications/
      echo -e "\033[0;32mAutoClick installed successfully.\033[0m"
    else
      echo -e "\033[0;32mAutoClick is already installed.\033[0m"
    fi
  '';
}
