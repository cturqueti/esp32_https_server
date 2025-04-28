#!/bin/bash
set -e

# Limpeza
rm -f exampleca.* example.* cert.h private_key.h

#------------------------------------------------------------------------------
# 1. Criar uma CA (Autoridade Certificadora) válida
#------------------------------------------------------------------------------
openssl genrsa -out exampleca.key 2048  # Usar 2048 bits para maior segurança

cat > exampleca.cnf << EOF  
[ req ]
distinguished_name = req_distinguished_name
x509_extensions    = v3_ca
prompt             = no
[ req_distinguished_name ]
C  = DE
ST = BE
L  = Berlin
O  = MyCompany
CN = myca.local
[ v3_ca ]
basicConstraints       = critical, CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF

# Gerar certificado autoassinado da CA (válido por 10 anos)
openssl req -x509 -new -nodes -key exampleca.key -sha256 -days 3650 -out exampleca.crt -config exampleca.cnf

#------------------------------------------------------------------------------
# 2. Criar certificado para o ESP32
#------------------------------------------------------------------------------
openssl genrsa -out example.key 2048

cat > example.csr.cnf << EOF  
[ req ]
distinguished_name = req_distinguished_name
prompt             = no
[ req_distinguished_name ]
C  = DE
ST = BE
L  = Berlin
O  = MyCompany
CN = esp32.local
EOF

# Gerar CSR (Certificate Signing Request)
openssl req -new -key example.key -out example.csr -config example.csr.cnf

# Criar arquivo de extensão para o certificado do ESP32
cat > example.ext << EOF  
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment
subjectAltName         = DNS:esp32.local
EOF

# Assinar o certificado com a CA (adicionando extensões)
openssl x509 -req -in example.csr -CA exampleca.crt -CAkey exampleca.key -CAcreateserial \
    -out example.crt -days 3650 -sha256 -extfile example.ext

# Verificar (agora deve funcionar)
openssl verify -CAfile exampleca.crt example.crt

#------------------------------------------------------------------------------
# 3. Converter para DER e gerar arquivos .h
#------------------------------------------------------------------------------
openssl rsa -in example.key -outform DER -out example.key.DER
openssl x509 -in example.crt -outform DER -out example.crt.DER

# Gerar cert.h e private_key.h
xxd -i example.crt.DER > cert.h
xxd -i example.key.DER > private_key.h

echo ""
echo "✅ Certificados criados com sucesso!"
echo "-----------------------------------"
echo "Arquivos gerados:"
echo "  - cert.h"
echo "  - private_key.h"