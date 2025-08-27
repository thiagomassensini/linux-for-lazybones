#!/bin/bash
# Script de backup interativo via SMB/SFTP
# ATENÇÃO: Nunca insira dados reais (senhas, IPs, usuários) diretamente neste script. Use apenas prompts.

set -e
clear
echo "==== Backup com Partclone - Interativo ===="

# Verifica root
if [[ $EUID -ne 0 ]]; then
	echo "Execute como root!"
	exit 1
fi

# Instala dependências
echo -e "\nInstalando dependências..."
apt update -qq
apt install -y -qq partclone cifs-utils sshfs pv dialog

# Pergunta tipo de destino
echo -e "\nEscolha o tipo de destino:"
echo "1 - Local"
echo "2 - Compartilhamento Windows (SMB)"
echo "3 - Servidor remoto via SFTP"
read -rp "Opção [1/2/3]: " DEST_OPCAO

DEST_DIR=""

if [[ "$DEST_OPCAO" == "1" ]]; then
	read -rp "Digite o caminho local para salvar o backup (ex: /mnt/ssd): " DEST_DIR
elif [[ "$DEST_OPCAO" == "2" ]]; then
	read -rp "IP do servidor SMB: " SMB_IP
	read -rp "Compartilhamento (ex: backups): " SMB_SHARE
	read -rp "Usuário: " SMB_USER
	read -rsp "Senha: " SMB_PASS
	echo ""
	mkdir -p /mnt/backup_dest
	mount -t cifs "//${SMB_IP}/${SMB_SHARE}" /mnt/backup_dest -o username="${SMB_USER}",password="${SMB_PASS}",vers=3.0
	DEST_DIR="/mnt/backup_dest"
elif [[ "$DEST_OPCAO" == "3" ]]; then
	read -rp "Usuário SSH: " SFTP_USER
	read -rp "IP do servidor SFTP: " SFTP_IP
	mkdir -p /mnt/backup_dest
	sshfs "${SFTP_USER}@${SFTP_IP}:" /mnt/backup_dest
	DEST_DIR="/mnt/backup_dest"
else
	echo "Opção inválida."
	exit 1
fi

# Lista diretórios e permite escolha
echo -e "\nDiretórios disponíveis em $DEST_DIR:"
select DIR_ESCOLHIDO in $(ls "$DEST_DIR"); do
	if [[ -n "$DIR_ESCOLHIDO" ]]; then
		DEST_FINAL="${DEST_DIR}/${DIR_ESCOLHIDO}"
		break
	else
		echo "Escolha inválida."
	fi
done

# Lista partições disponíveis
echo -e "\nPartições disponíveis para backup:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT -nr | grep -v "^loop"

read -rp "Digite o caminho da partição para backup (ex: /dev/nvme1n1p2): " PARTICAO
check_montado=$(mount | grep "$PARTICAO" || true)
if [[ -n "$check_montado" ]]; then
	echo "Partição está montada. Desmonte antes de continuar."
	exit 1
fi

FSTYPE=$(lsblk -no FSTYPE "$PARTICAO")
if [[ "$FSTYPE" != "ext4" ]]; then
	echo "Partição não é ext4. Tipo detectado: $FSTYPE. Pode não funcionar."
	read -rp "Deseja continuar mesmo assim? [s/N]: " CONFIRM
	[[ "$CONFIRM" =~ ^[sS]$ ]] || exit 1
fi

# Nome final do arquivo
DATA=$(date +%Y%m%d_%H%M%S)
ARQ_BACKUP="${DEST_FINAL}/backup_$(basename $PARTICAO)_${DATA}.img"

echo -e "\nIniciando backup para $ARQ_BACKUP..."
partclone.ext4 -c -s "$PARTICAO" -o "$ARQ_BACKUP"

echo -e "\nBackup concluído com sucesso!"
