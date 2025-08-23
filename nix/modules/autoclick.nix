{ pkgs, ... }:

let
  autoClickUrl = "https://tars.mahdi.jp/apps/autoclick.zip";
  autoClickApp = "AutoClick.app";
  applicationsDir = "/Applications";
in
{
  system.activationScripts.postActivation.text = ''
    echo "Checking for AutoClick installation..."
    if [ ! -d "${applicationsDir}/${autoClickApp}" ]; then
      echo -e "\033[0;34mAutoClick not found. Downloading and installing...\033[0m"
      ${pkgs.curl}/bin/curl -L "${autoClickUrl}" -o /tmp/autoclick.zip -s
      ${pkgs.unzip}/bin/unzip -q -o /tmp/autoclick.zip -d /tmp
      mv /tmp/${autoClickApp} ${applicationsDir}/
      rm /tmp/autoclick.zip
      echo -e "\033[0;32mAutoClick installed successfully.\033[0m"
    else
      echo -e "\033[0;32mAutoClick is already installed.\033[0m"
    fi
  '';
}
