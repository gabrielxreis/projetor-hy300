#!/bin/zsh
# Abre a tela do projetor HY300 numa janela do Mac para controlar com o mouse e o teclado.
# Precisa: projetor ligado, no mesmo Wi-Fi, com "Internet Adb" ligado nas opcoes do programador.
# O ADB deste projetor usa a porta 3268.

export PATH="/opt/homebrew/bin:$PATH"
LOG="$HOME/Library/Application Support/Projetor-HY300/ultimo-uso.log"
mkdir -p "${LOG:h}"; exec > >(tee "$LOG") 2>&1
PORTA=3268
IP_SALVO="$HOME/Library/Application Support/Projetor-HY300/ip.txt"
IP=$(cat "$IP_SALVO" 2>/dev/null || echo 0.0.0.0)  # 0.0.0.0 = procura na rede

conectar() { adb connect "$1:$PORTA" 2>&1 | grep -q "connected to" ; }

echo "Procurando o projetor em $IP..."
if ! conectar "$IP"; then
  echo "Nao respondeu. Procurando na rede (uns 10 segundos)..."
  REDE=$(ipconfig getifaddr en0 || ipconfig getifaddr en1); REDE=${REDE%.*}
  IP=""
  for i in $(seq 1 254); do (nc -z -G 1 $REDE.$i $PORTA 2>/dev/null && echo $REDE.$i) & done | head -1 | read IP
  wait
  if [[ -z "$IP" ]] || ! conectar "$IP"; then
    echo ""
    echo "Nao achei o projetor. Confira se ele esta ligado, no Wi-Fi de casa,"
    echo "e com 'Internet Adb' ligado. Depois rode de novo."
    read -k1 "?Aperte qualquer tecla para fechar."
    exit 1
  fi
fi
mkdir -p "${IP_SALVO:h}"; echo "$IP" > "$IP_SALVO"
echo "Conectado em $IP. Ligando o modo rapido..."
zsh "$HOME/Library/Application Support/Projetor-HY300/turbo.sh"
adb connect "$IP:$PORTA" >/dev/null 2>&1
echo "Abrindo a janela..."

# Imagem leve (o processador do projetor e fraco), sem som no Mac (o som sai no projetor),
# e a tela do projetor continua ligada normalmente.
# Logo depois de ligar, o projetor pode recusar a primeira tentativa: tenta ate 4 vezes.
for tentativa in 1 2 3 4; do
inicio=$SECONDS
scrcpy -s "$IP:$PORTA" \
  --window-title "Projetor" \
  --max-size 960 --video-bit-rate 2M --max-fps 20 \
  --no-audio --stay-awake --shortcut-mod=lsuper \
  --keyboard=sdk --mouse=sdk --prefer-text
# Se a janela ficou aberta mais de 15 s, foi uso normal (voce fechou): encerra.
(( SECONDS - inicio > 15 )) && break
echo "O projetor ainda nao respondeu (tentativa $tentativa). Tentando de novo em 5 s..."
adb -s "$IP:$PORTA" shell pkill -f scrcpy-server 2>/dev/null
sleep 5
done
