#!/bin/zsh
# Compila o app "Configurações" do Cinema em Casa e gera configuracoes.apk assinado.
set -e
cd "${0:A:h}"
: ${CHAVE_SENHA:?"Defina a senha da chave: CHAVE_SENHA=suasenha zsh build.sh"}; export CHAVE_SENHA
export JAVA_HOME=$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
SDK=$HOME/Library/Android/sdk; BT=$SDK/build-tools/34.0.0; JAR=$SDK/platforms/android-33/android.jar
rm -rf build; mkdir -p build/res build/classes build/dex

$BT/aapt2 compile --dir res -o build/res/
$BT/aapt2 link -o build/base.apk -I $JAR --manifest AndroidManifest.xml build/res/*.flat --java build/gen --auto-add-overlay
javac -source 8 -target 8 -bootclasspath $JAR -classpath $JAR -d build/classes \
  src/com/cinemaemcasa/configuracoes/*.java $(find build/gen -name '*.java') 2>&1 | grep -v "warning" || true
$BT/d8 --lib $JAR --min-api 21 --output build/dex $(find build/classes -name '*.class')
cp build/base.apk build/unsigned.apk
(cd build/dex && zip -q ../unsigned.apk classes.dex)
$BT/zipalign -f 4 build/unsigned.apk build/aligned.apk

# chave propria do app (criada uma vez, fica nesta pasta)
[[ -f chave.jks ]] || keytool -genkeypair -keystore chave.jks -alias cinema -keyalg RSA -keysize 2048 \
  -validity 36500 -storepass "$CHAVE_SENHA" -keypass "$CHAVE_SENHA" -dname "CN=Cinema em Casa" >/dev/null 2>&1
$BT/apksigner sign --ks chave.jks --ks-pass env:CHAVE_SENHA --key-pass env:CHAVE_SENHA \
  --out configuracoes.apk build/aligned.apk
$BT/apksigner verify configuracoes.apk && echo "OK: configuracoes.apk"
