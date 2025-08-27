
#!/bin/bash
# Script para ajustar permissões de diretórios web
# Edite a variável DIR conforme sua necessidade antes de executar.

DIR="/var/www/html/scripts" # Altere para o diretório desejado

sudo chmod -R 755 "$DIR"
sudo chown -R www-data:www-data "$DIR"

echo "Permissões e propriedade aplicadas em $DIR"
