#!/usr/bin/env bash
# Genera coop.pkpass firmado para Apple Wallet.
# Requisitos (cuenta Apple Developer):
#   certs/pass.p12  -> certificado "Pass Type ID" exportado desde Llavero
#   certs/wwdr.pem  -> Apple WWDR G4 (https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer, convertido a PEM)
# Antes, edita pass/pass.json: passTypeIdentifier y teamIdentifier con los tuyos.
set -euo pipefail
cd "$(dirname "$0")"
P12_PASS="${P12_PASS:-}"
rm -rf build && mkdir build && cp pass/* build/
cd build
python3 - <<'PY'
import hashlib, json, os
m = {f: hashlib.sha1(open(f, 'rb').read()).hexdigest() for f in sorted(os.listdir('.'))}
json.dump(m, open('manifest.json', 'w'), indent=2)
PY
openssl pkcs12 -in ../certs/pass.p12 -clcerts -nokeys -out cert.pem -passin pass:"$P12_PASS" -legacy 2>/dev/null \
  || openssl pkcs12 -in ../certs/pass.p12 -clcerts -nokeys -out cert.pem -passin pass:"$P12_PASS"
openssl pkcs12 -in ../certs/pass.p12 -nocerts -nodes -out key.pem -passin pass:"$P12_PASS" -legacy 2>/dev/null \
  || openssl pkcs12 -in ../certs/pass.p12 -nocerts -nodes -out key.pem -passin pass:"$P12_PASS"
openssl smime -binary -sign -certfile ../certs/wwdr.pem -signer cert.pem -inkey key.pem \
  -in manifest.json -out signature -outform DER
rm cert.pem key.pem
zip -q -r ../coop.pkpass pass.json manifest.json signature *.png
cd .. && rm -rf build
echo "Listo: coop.pkpass (envíatelo por AirDrop/Mail/iCloud y ábrelo en el iPhone)"
