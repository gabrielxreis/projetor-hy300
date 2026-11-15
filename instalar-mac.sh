#!/bin/zsh
# Instala a parte do Mac: adb/scrcpy, o turbo.sh + vigia e o LaunchAgent que reaplica tudo a cada 20 s.
# Uso: zsh instalar-mac.sh <ip-do-projetor>
set -e
cd "${0:A:h}"
IP=${1:?"Uso: zsh instalar-mac.sh <ip-do-projetor>"}
A="$HOME/Library/Application Support/Projetor-HY300"
brew list --cask android-platform-tools >/dev/null 2>&1 || brew install --cask android-platform-tools
brew list scrcpy >/dev/null 2>&1 || brew install scrcpy
mkdir -p "$A"
echo "$IP" > "$A/ip.txt"
cp scripts/turbo.sh scripts/desligar-direto.sh "$A/"
P="$HOME/Library/LaunchAgents/com.projetor-hy300.turbo.plist"
sed "s#__HOME__#$HOME#g" mac/com.projetor-hy300.turbo.plist > "$P"
launchctl unload "$P" 2>/dev/null || true
launchctl load "$P"
cp mac/*.command "$HOME/Desktop/"; chmod +x "$HOME/Desktop/"*Projetor*.command
echo "Pronto. LaunchAgent ativo e atalhos na Mesa."
