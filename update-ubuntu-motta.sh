
#!/bin/bash
# Script de atualização automatizada para Ubuntu
# ATENÇÃO: Não insira dados sensíveis neste script. Uso genérico para sistemas Ubuntu.

# Verifica se está sendo executado como root
if [ "$EUID" -ne 0 ]; then
	echo "Este script deve ser executado como root. Use: sudo $0"
	exit 1
fi

# Definição de cores ANSI
if tput setaf 1 &> /dev/null; then
	RED='\033[1;31m'
	GREEN='\033[1;32m'
	YELLOW='\033[1;33m'
	BLUE='\033[1;34m'
	MAGENTA='\033[1;35m'
	CYAN='\033[1;36m'
	NC='\033[0m' # Sem cor
else
	RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''; NC=''
fi

LOGFILE="/var/log/upgrade_ubuntu_$(date +"%Y-%m-%d_%H-%M-%S").log"

log() {
	echo -e "${MAGENTA}$(date +"%Y-%m-%d %H:%M:%S") - $1${NC}" | tee -a "$LOGFILE"
}

verificar_distribuicao() {
	if [ -f /etc/os-release ]; then
		source /etc/os-release
		DISTRO="$NAME"
		VERSAO="$VERSION_ID"
		log "Detectado: ${CYAN}$DISTRO ($VERSAO)${NC}"

		if [[ "$ID" == "ubuntu" ]]; then
			log "Ubuntu detectado! Iniciando atualização."
		else
			log "Distribuição não suportada: $DISTRO"
			exit 1
		fi
	else
		log "Não foi possível determinar a distribuição."
		exit 1
	fi
}

corrigir_pacotes() {
	log "Corrigindo possíveis travas de pacotes..."
	sudo rm -f /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/cache/apt/archives/lock
	sudo dpkg --configure -a || log "Erro ao configurar pacotes!"
	sudo apt install -f -y || log "Erro ao instalar dependências!"
}

atualizar_sistema() {
	log "Atualizando lista de pacotes..."
	sudo apt update -y

	log "Executando upgrade completo..."
	DEBIAN_FRONTEND=noninteractive sudo apt full-upgrade -y

	log "Limpando o sistema..."
	sudo apt autoremove -y
	sudo apt autoclean -y

	log "Sistema atualizado com sucesso!"
}

atualizar_drivers_nvidia() {
	log "Procurando placas NVIDIA..."
	if lspci | grep -i nvidia &>/dev/null; then
		log "GPU NVIDIA detectada! Atualizando drivers."
		sudo add-apt-repository -y ppa:graphics-drivers/ppa
		sudo apt update -y
		DRIVER=$(ubuntu-drivers devices | grep "driver :" | grep recommended | awk '{print $3}' | head -n 1)

		if [ -n "$DRIVER" ]; then
			log "Instalando driver recomendado: $DRIVER"
			sudo apt install -y "$DRIVER"
		else
			log "Nenhum driver recomendado encontrado!"
		fi
	else
		log "Nenhuma GPU NVIDIA encontrada."
	fi
}

verificar_reboot() {
	if [ -f /var/run/reboot-required ]; then
		log "É necessário reiniciar o sistema! Deseja reiniciar agora? (s/N)"
		read -r resposta
		case "$resposta" in
			[Ss]) log "Reiniciando... Até logo!"; sudo reboot ;;
			*) log "Reinicialização adiada." ;;
		esac
	fi
}
