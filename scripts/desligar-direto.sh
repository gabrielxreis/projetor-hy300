#!/system/bin/sh
# Roda NO PROJETOR (como root). Um toque no botao de energia do controle desliga direto:
# quando o sistema mostra "Pressione o botao de energia novamente ou OK para desligar a energia",
# este vigia confirma o OK sozinho. Fica parado (sem gastar CPU) esperando a tecla.
# Iniciado pelo turbo.sh do Mac a cada boot. (A versao "espera/dormir" foi testada e nao
# funciona bem neste projetor: o hardware nao tem standby de verdade.)
while true; do
  getevent -l 2>/dev/null | grep -m1 -qE "KEY_POWER +DOWN"
  sleep 0.8
  if dumpsys window 2>/dev/null | grep -q "mCurrentFocus.*LegacyGlobalActions"; then
    input keyevent DPAD_CENTER
    sleep 3
  fi
done
