#!/bin/zsh
# Dois cliques depois de ligar o projetor: deixa ele na velocidade maxima ate desligar.
A="$HOME/Library/Application Support/Projetor-HY300"
zsh "$A/turbo.sh"
IP=$(cat "$A/ip.txt" 2>/dev/null) || { echo "Rode antes: zsh instalar-mac.sh <ip-do-projetor>"; sleep 3; exit 1; }
G=$(/opt/homebrew/bin/adb -s "$IP:3268" shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null | tr -d '\r')
if [[ "$G" == "performance" ]]; then echo "Projetor no modo rapido."; else echo "Nao achei o projetor ligado. Ligue e tente de novo."; fi
sleep 3
