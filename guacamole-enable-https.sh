
#!/bin/bash
set -e

# ===============================
# ATIVAR HTTPS COM CERTIFICADO SELF-SIGNED NO TOMCAT9 (Guacamole)
# ===============================

DOMAIN="guacamole.local"    # Altere para o seu domínio/CNAME
read -rsp "Digite a senha do keystore (não será exibida): " KEYSTORE_PASSWORD
echo
KEYSTORE_PATH="/etc/ssl/guacamole-keystore.jks"
TOMCAT_CONFIG="/etc/tomcat9/server.xml"

echo "Gerando certificado SSL self-signed..."
keytool -genkey -alias guacamole_ssl -keyalg RSA -keysize 2048 -validity 365 \
	-keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD" \
	-dname "CN=${DOMAIN}, OU=TI, O=Empresa, L=Cidade, ST=Estado, C=BR"

echo "Certificado gerado: $KEYSTORE_PATH"

echo "Criando backup do server.xml..."
cp "$TOMCAT_CONFIG" "${TOMCAT_CONFIG}.bak"

echo "Adicionando configuração HTTPS no Tomcat9..."
if ! grep -q "Connector port=\"8443\"" "$TOMCAT_CONFIG"; then
cat <<EOF >> "$TOMCAT_CONFIG"

<!-- SSL Connector - Guacamole Self-Signed -->
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
					 maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
					 keystoreFile="$KEYSTORE_PATH" keystorePass="$KEYSTORE_PASSWORD"
					 clientAuth="false" sslProtocol="TLS"/>
EOF
fi

echo "Reiniciando Tomcat9..."
systemctl restart tomcat9

echo ""
echo "HTTPS configurado com sucesso!"
echo "Acesse agora: https://SEU_IP:8443/guacamole"
echo "O navegador vai avisar que o certificado não é confiável (self-signed, esperado)."
echo ""
echo "DICA: Quando quiser usar Let's Encrypt, basta substituir o keystore/cert no Tomcat."
