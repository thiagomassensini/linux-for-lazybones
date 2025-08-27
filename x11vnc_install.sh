#!/bin/bash

USER_NAME=$(whoami)
VNC_PASSWD_FILE="/home/$USER_NAME/.vnc/passwd"

echo "Instalando x11vnc..."
sudo apt update && sudo apt install -y x11vnc

echo "Criando diretório da senha (se necessário)..."
mkdir -p /home/$USER_NAME/.vnc

echo "Digite a senha que será usada no VNC:"
x11vnc -storepasswd "$VNC_PASSWD_FILE"

echo "Ajustando permissões do arquivo de senha..."
chmod 600 "$VNC_PASSWD_FILE"
chown "$USER_NAME:$USER_NAME" "$VNC_PASSWD_FILE"

echo "Criando serviço systemd..."

sudo bash -c "cat <<EOF > /etc/systemd/system/x11vnc.service
[Unit]
Description=Servidor VNC x11vnc
After=display-manager.service

[Service]
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth $VNC_PASSWD_FILE -shared -display :0
User=$USER_NAME
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"

echo "Habilitando e iniciando o serviço..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl restart x11vnc.service

echo ""
echo "Instalação e configuração concluídas com sucesso."
echo "Para acessar o VNC, utilize um cliente VNC apontando para o IP deste servidor na porta padrão."
