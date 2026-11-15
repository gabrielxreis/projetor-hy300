#!/bin/zsh
# Desfaz a otimizacao do projetor HY300 (Rockchip RK3326, Android 12) feita em 13/11/2026.
# Uso: ligar "Depuracao USB" e "Internet Adb" no projetor e rodar:  zsh restaurar.sh [ip]
# O ADB deste projetor usa a porta 3268 (nao a 5555).

IP=${1:?"Uso: zsh restaurar.sh <ip-do-projetor> [compilacao]"}
D="$IP:3268"
adb connect "$D" || exit 1

for p in com.rockchip.devicetest com.shzhtxcz.txcz.test com.bozee.usbdisplay com.sszztxr.oott com.android.mgstv com.shzhtxcz.txbox.launcher com.rockchip.itvbox com.netflix.mediaclient; do
  adb -s "$D" shell pm enable "$p"
done

adb -s "$D" shell pm unhide com.rockchip.itvbox
adb -s "$D" shell pm enable com.sszztxr.app

for c in com.sszztxr.app/com.tx.app.receiver.BootBroadcastReceiver com.rockchips.mediacenter/com.rockchips.mediacenter.service.BootReceiver com.rockchip.itvbox/com.google.android.RkService com.rockchip.itvbox/com.bd.service.AliveService com.android.cellbroadcastreceiver/com.android.cellbroadcastreceiver.CellBroadcastReceiver; do
  adb -s "$D" root >/dev/null 2>&1; adb -s "$D" shell pm enable "$c"
done

# Valor original: 0.5 nas janelas e transicoes (ja vinha assim); a do animador nao estava definida.
adb -s "$D" shell settings put global window_animation_scale 0.5
adb -s "$D" shell settings put global transition_animation_scale 0.5
adb -s "$D" shell settings delete global animator_duration_scale
adb -s "$D" shell settings delete secure enabled_accessibility_services
adb -s "$D" shell cmd package set-home-activity com.shzhtxcz.txbox.launcher/com.shzhtxcz.txbox.SplashActivity

# Para descartar tambem a compilacao nativa dos apps, rode com o segundo argumento "compilacao":
if [[ "$2" == "compilacao" ]]; then
  adb -s "$D" shell 'pm compile --reset -a'
fi

echo "Pronto. Reinicie o projetor."
