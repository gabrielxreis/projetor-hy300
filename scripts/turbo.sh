#!/bin/zsh
# Projetor HY300 (RK3326) do Cinema em Casa. Roda no Mac a cada 20 s (LaunchAgent) e, quando
# o projetor esta ligado:
#  1) deixa CPU, GPU e memoria em "performance" (modo rapido);
#  2) garante o vigia "desligar direto" rodando (confirma sozinho o aviso do botao de energia).
# As duas coisas somem quando o projetor desliga; este script reaplica quando ele volta.
# Para parar tudo:  launchctl unload ~/Library/LaunchAgents/com.projetor-hy300.turbo.plist
# e reinicie o projetor.

export PATH="/opt/homebrew/bin:$PATH"
A="$HOME/Library/Application Support/Projetor-HY300"
IP=$(cat "$A/ip.txt" 2>/dev/null) || exit 0
D="$IP:3268"

nc -z -G 2 "$IP" 3268 2>/dev/null || exit 0          # projetor desligado: nada a fazer
adb connect "$D" >/dev/null 2>&1

atual=$(adb -s "$D" shell cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null | tr -d '\r')
vigia=$(adb -s "$D" shell 'pgrep -f desligar-direto.sh' 2>/dev/null | tr -d '\r')
[[ "$atual" == "performance" && -n "$vigia" ]] && exit 0   # tudo ja aplicado

if [[ "$(adb -s "$D" shell id -u 2>/dev/null | tr -d '\r')" != "0" ]]; then
  adb -s "$D" root >/dev/null 2>&1; sleep 4; adb connect "$D" >/dev/null 2>&1; sleep 2
fi

if [[ "$atual" != "performance" ]]; then
  adb -s "$D" shell '
  for c in 0 1 2 3; do echo performance > /sys/devices/system/cpu/cpu$c/cpufreq/scaling_governor; done
  echo performance > /sys/class/devfreq/ff400000.gpu/governor
  echo performance > /sys/class/devfreq/dmc/governor
  ' 2>/dev/null
  echo "$(date '+%d/%m %H:%M') modo rapido aplicado em $IP" >> "$A/turbo.log"
fi

if [[ -z "$(adb -s "$D" shell 'pgrep -f desligar-direto.sh' 2>/dev/null | tr -d '\r')" ]]; then
  adb -s "$D" push "$A/desligar-direto.sh" /data/local/tmp/desligar-direto.sh >/dev/null 2>&1
  adb -s "$D" shell 'chmod 755 /data/local/tmp/desligar-direto.sh; setsid nohup sh /data/local/tmp/desligar-direto.sh >/dev/null 2>&1 < /dev/null &' >/dev/null 2>&1
  echo "$(date '+%d/%m %H:%M') vigia desligar-direto iniciado em $IP" >> "$A/turbo.log"
fi
