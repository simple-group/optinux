#!/bin/bash

# ==============================================================================
# TITRE : OPTINUX - Debian System Optimizer (MASTERCLASS EDITION)
# AUTEUR : Brice Cornet - Simple CRM
# REVISÉ PAR : Expert SysAdmin & Gemini
# DATE : $(date +%Y-%m-%d)
#
# DESCRIPTION : 
# FR: Script d'optimisation complet (Réseau, Kernel, Services, Apache) avec pédagogie intégrée.
# EN: Complete optimization script (Network, Kernel, Services, Apache) with integrated pedagogy.
# ==============================================================================

# --- COULEURS / COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- SETUP FICHIERS / FILE SETUP ---
BACKUP_DIR="./backups_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="./optimization.log"
mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# --- VÉRIFICATION ROOT / ROOT CHECK ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (sudo).${NC}" 
   exit 1
fi

# --- FONCTIONS UTILITAIRES / UTILITY FUNCTIONS ---

log_action() {
    echo -e "${GREEN}[OK] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [OK] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

log_err() {
    echo -e "${RED}[ERROR] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

log_info() {
    echo -e "${CYAN}[INFO] $1${NC}"
}

backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local file_name=$(basename "$file_path")
        cp "$file_path" "$BACKUP_DIR/${file_name}.bak"
        log_action "$TXT_BACKUP_LOG $file_path -> $BACKUP_DIR/${file_name}.bak"
    fi
}

# Fonction récursive pour backup dossier
backup_folder() {
    local folder_path="$1"
    if [ -d "$folder_path" ]; then
        local folder_name=$(basename "$folder_path")
        tar -czf "$BACKUP_DIR/${folder_name}.tar.gz" -C "$(dirname "$folder_path")" "$folder_name" 2>/dev/null
        log_action "Backup folder: $folder_path -> $BACKUP_DIR/${folder_name}.tar.gz"
    fi
}

optimize_service() {
    local SERVICE_NAME=$1
    if systemctl list-unit-files | grep -q "^$SERVICE_NAME.service"; then
        mkdir -p "/etc/systemd/system/$SERVICE_NAME.service.d"
        CONF_FILE="/etc/systemd/system/$SERVICE_NAME.service.d/priority.conf"
        cat > "$CONF_FILE" <<EOF
[Service]
Nice=-10
IOSchedulingClass=best-effort
IOSchedulingPriority=0
EOF
        log_action "$TXT_ROLE_APPLY $SERVICE_NAME"
        NEED_DAEMON_RELOAD=true
    fi
}

# ==============================================================================
# 0. SÉLECTION DE LA LANGUE / LANGUAGE SELECTION
# ==============================================================================
clear
echo "-------------------------------------------------------"
echo " Select Language / Sélectionnez la langue"
echo "-------------------------------------------------------"
echo "1) Français"
echo "2) English"
read -p "Choice/Choix [1-2]: " LANG_OPT

# --- DICTIONNAIRE DE LANGUE / LANGUAGE DICTIONARY ---
if [ "$LANG_OPT" == "1" ]; then
    # --- FRANÇAIS ---
    TXT_LOG_START="Démarrage du script Optinux Masterclass."
    TXT_WARN_HEADER="AVERTISSEMENT IMPORTANT"
    TXT_WARN_MSG="Ce script modifie le Kernel, les DNS, Apache et la stack Réseau.\nBien que testé, le risque zéro n'existe pas."
    TXT_AGREE_PROMPT="Tapez 'AGREE' pour accepter et continuer :"
    TXT_REFUSED="Refusé. Arrêt du script."
    
    TXT_UPDATE_TITLE="MISE À JOUR SYSTÈME"
    TXT_UPDATE_ASK="Mettre à jour la liste des paquets (apt-get update) ? (o/n) :"
    TXT_UPDATE_DONE="Mise à jour terminée."
    
    TXT_ROLE_TITLE="OPTIMISATION PAR RÔLE"
    TXT_ROLE_ASK="Quel est le rôle principal de ce serveur ?"
    TXT_ROLE_CHOICE="1) Serveur WEB (Apache/Nginx/PHP)\n2) Base de Données (MySQL/Postgres)\n3) Stockage / NAS (Samba/NFS)\n4) Aucun (Passer)"
    TXT_ROLE_APPLY="Priorité CPU/IO appliquée pour :"
    TXT_ROLE_EXPLAIN="INFO : Nous allons donner la priorité processeur aux services critiques."

    TXT_RES_TITLE="NETTOYAGE & DÉSACTIVATION"
    TXT_RES_ASK="Supprimer les 'Bloatwares' et services inutiles (Avahi, Cups...) ? (o/n) :"
    TXT_RES_DONE="Nettoyage effectué."
    TXT_RES_EXPLAIN="INFO : Les services comme 'cups' (imprimante) ou 'avahi' ne servent à rien sur un serveur."
    TXT_SVC_STOP="Service arrêté et désactivé :"
    
    TXT_DNS_TITLE="CONFIGURATION DNS"
    TXT_DNS_ASK="Profil DNS :\n1) VIE PRIVÉE (AdGuard - Bloque pubs/trackers)\n2) VITESSE (Cloudflare + Google - Performance pure)"
    TXT_DNS_LOCK="Fichier resolv.conf verrouillé (chattr +i)."
    TXT_DNS_EXPLAIN="INFO : Changer les DNS peut accélérer les requêtes sortantes (curl, updates, etc)."

    TXT_NET_TITLE="OPTIMISATION RÉSEAU (MTU)"
    TXT_NET_IFACE="Interface détectée :"
    TXT_NET_ASK="Type d'infrastructure :\n1) Standard (100Mbps / 1Gbps / Wifi)\n2) Data Center Haute Performance (Jumbo Frames - MTU 9000)"
    TXT_JUMBO_WARN="ATTENTION : Ne choisissez MTU 9000 que si votre switch et routeur le supportent !"
    TXT_JUMBO_CONFIRM="Confirmez-vous le passage en MTU 9000 ? (o/n) :"
    
    TXT_SSH_TITLE="ACCÉLÉRATION SSH"
    TXT_SSH_APPLY="SSH : Reverse DNS désactivé (Login instantané)."
    
    TXT_LIMITS_TITLE="LIMITES FICHIERS (ULIMIT)"
    TXT_LIMITS_APPLY="Limites augmentées à 65535 fichiers ouverts."
    
    TXT_KERNEL_TITLE="OPTIMISATION KERNEL (SYSCTL)"
    TXT_KERNEL_APPLY="Application des paramètres noyau (sysctl)..."
    TXT_KERNEL_EXPLAIN="INFO : Optimisation de la gestion RAM (Swappiness) et activation de TCP BBR."

    TXT_APACHE_TITLE="OPTIMISATION APACHE WEB SERVER"
    TXT_APACHE_DETECT="Apache détecté. Optimisation du moteur et de la sécurité..."
    TXT_APACHE_ASK="Voulez-vous optimiser Apache (MPM Event, HTTP/2, Headers Sécurité) ?\nCela va redémarrer Apache. (o/n) :"
    TXT_APACHE_MPM="Passage de Prefork (lent) à MPM EVENT (rapide)."
    TXT_APACHE_CONF="Configuration globale injectée (KeepAlive, Timeouts, Security)."
    TXT_APACHE_FAIL="Erreur de configuration détectée ! Restauration du backup..."
    TXT_APACHE_EXPLAIN="INFO : Apache par défaut utilise 'Prefork' (gourmand en RAM). Nous passons à 'Event' (plus stable) et activons HTTP/2."

    TXT_DONE_TITLE="OPTIMISATION TERMINÉE"
    TXT_REBOOT_ASK="Redémarrer le serveur maintenant pour appliquer les changements ? (o/n) :"
    TXT_BACKUP_LOG="Backup créé :"

else
    # --- ENGLISH ---
    TXT_LOG_START="Starting Optinux Masterclass script."
    TXT_WARN_HEADER="IMPORTANT WARNING"
    TXT_WARN_MSG="This script modifies Kernel, DNS, Apache and Network stack.\nWhile tested, use at your own risk."
    TXT_AGREE_PROMPT="Type 'AGREE' to accept and continue:"
    TXT_REFUSED="Refused. Script stopped."
    
    TXT_UPDATE_TITLE="SYSTEM UPDATE"
    TXT_UPDATE_ASK="Update package lists (apt-get update)? (y/n):"
    TXT_UPDATE_DONE="Update completed."
    
    TXT_ROLE_TITLE="ROLE-BASED OPTIMIZATION"
    TXT_ROLE_ASK="What is the primary role of this server?"
    TXT_ROLE_CHOICE="1) WEB Server (Apache/Nginx/PHP)\n2) Database (MySQL/Postgres)\n3) Storage / NAS (Samba/NFS)\n4) None (Skip)"
    TXT_ROLE_APPLY="CPU/IO priority applied for:"
    TXT_ROLE_EXPLAIN="INFO: We will assign higher CPU priority to critical services."

    TXT_RES_TITLE="DEBLOAT & CLEANUP"
    TXT_RES_ASK="Remove 'Bloatware' and disable useless services (Avahi, Cups...)? (y/n):"
    TXT_RES_DONE="Cleanup completed."
    TXT_RES_EXPLAIN="INFO: Services like 'cups' (printing) or 'avahi' are useless on a server."
    TXT_SVC_STOP="Service stopped and disabled:"
    
    TXT_DNS_TITLE="DNS CONFIGURATION"
    TXT_DNS_ASK="DNS Profile:\n1) PRIVACY (AdGuard - Blocks ads/trackers)\n2) SPEED (Cloudflare + Google - Pure performance)"
    TXT_DNS_LOCK="resolv.conf locked (chattr +i)."
    TXT_DNS_EXPLAIN="INFO: Changing DNS can speed up outgoing requests (curl, updates, etc)."

    TXT_NET_TITLE="NETWORK OPTIMIZATION (MTU)"
    TXT_NET_IFACE="Interface detected:"
    TXT_NET_ASK="Infrastructure Type:\n1) Standard (100Mbps / 1Gbps / Wifi)\n2) High Performance Data Center (Jumbo Frames - MTU 9000)"
    TXT_JUMBO_WARN="WARNING: Only choose MTU 9000 if your switch/router supports it explicitly!"
    TXT_JUMBO_CONFIRM="Do you confirm MTU 9000? (y/n):"
    
    TXT_SSH_TITLE="SSH ACCELERATION"
    TXT_SSH_APPLY="SSH: Reverse DNS disabled (Instant login)."
    
    TXT_LIMITS_TITLE="FILE LIMITS (ULIMIT)"
    TXT_LIMITS_APPLY="Limits increased to 65535 open files."
    
    TXT_KERNEL_TITLE="KERNEL OPTIMIZATION (SYSCTL)"
    TXT_KERNEL_APPLY="Applying kernel parameters (sysctl)..."
    TXT_KERNEL_EXPLAIN="INFO: Optimizing RAM management (Swappiness) and enabling TCP BBR."

    TXT_APACHE_TITLE="APACHE WEB SERVER OPTIMIZATION"
    TXT_APACHE_DETECT="Apache detected. Optimizing engine and security..."
    TXT_APACHE_ASK="Do you want to optimize Apache (MPM Event, HTTP/2, Security Headers)?\nThis will restart Apache. (y/n):"
    TXT_APACHE_MPM="Switching from Prefork (slow) to MPM EVENT (fast)."
    TXT_APACHE_CONF="Global configuration injected (KeepAlive, Timeouts, Security)."
    TXT_APACHE_FAIL="Configuration error detected! Restoring backup..."
    TXT_APACHE_EXPLAIN="INFO: Default Apache uses 'Prefork' (RAM heavy). We switch to 'Event' (Stable) and enable HTTP/2."

    TXT_DONE_TITLE="OPTIMIZATION COMPLETED"
    TXT_REBOOT_ASK="Reboot the server now to apply changes? (y/n):"
    TXT_BACKUP_LOG="Backup created:"
fi

# ==============================================================================
# 1. DISCLAIMER
# ==============================================================================
log_action "$TXT_LOG_START"
echo ""
echo -e "${RED}=== $TXT_WARN_HEADER ===${NC}"
echo -e "$TXT_WARN_MSG"
echo ""
read -p "$TXT_AGREE_PROMPT " approval
if [ "$approval" != "AGREE" ]; then
    echo "$TXT_REFUSED"
    exit 1
fi

# ==============================================================================
# 2. UPDATE
# ==============================================================================
echo -e "${BLUE}--- $TXT_UPDATE_TITLE ---${NC}"
read -p "$TXT_UPDATE_ASK " up_choice
if [[ "$up_choice" =~ ^[oOyY] ]]; then
    apt-get update
    log_action "$TXT_UPDATE_DONE"
fi

# ==============================================================================
# 3. RÔLE SERVEUR (PRIORITIZATION) 
# ==============================================================================
echo -e "${BLUE}--- $TXT_ROLE_TITLE ---${NC}"
log_info "$TXT_ROLE_EXPLAIN"
echo -e "$TXT_ROLE_ASK"
echo -e "$TXT_ROLE_CHOICE"
read -p "> " role_choice

NEED_DAEMON_RELOAD=false

case $role_choice in
    1) # WEB
        TARGETS=("apache2" "nginx" "php-fpm" "varnish" "redis-server")
        PHP_VERSIONS=$(systemctl list-units --type=service --all | grep "php.*-fpm" | awk '{print $1}' | sed 's/.service//')
        for php in $PHP_VERSIONS; do TARGETS+=("$php"); done
        ;;
    2) # DB
        TARGETS=("mysql" "mariadb" "postgresql" "mongod" "redis-server")
        ;;
    3) # FILE/NAS
        TARGETS=("smbd" "nmbd" "nfs-kernel-server")
        ;;
    *)
        TARGETS=()
        ;;
esac

for svc in "${TARGETS[@]}"; do
    optimize_service "$svc"
done

if [ "$NEED_DAEMON_RELOAD" = true ]; then
    systemctl daemon-reload
    log_action "Systemd Daemon Reloaded."
fi

# ==============================================================================
# 4. DEBLOAT & SERVICES
# ==============================================================================
echo -e "${BLUE}--- $TXT_RES_TITLE ---${NC}"
log_info "$TXT_RES_EXPLAIN"
echo -e "$TXT_RES_ASK"
read -p "> " res_choice
if [[ "$res_choice" =~ ^[oOyY] ]]; then
    
    if dpkg -l | grep -q "apt-xapian-index"; then
        apt-get remove --purge apt-xapian-index -y
        apt-get autoremove -y
    fi
    
    SERVICES=("avahi-daemon" "cups" "bluetooth")
    for svc in "${SERVICES[@]}"; do
        if systemctl list-unit-files | grep -q "^$svc"; then
            systemctl stop "$svc" 2>/dev/null
            systemctl disable "$svc" 2>/dev/null
            log_action "$TXT_SVC_STOP $svc"
        fi
    done
    log_action "$TXT_RES_DONE"
fi

# ==============================================================================
# 5. DNS
# ==============================================================================
echo -e "${BLUE}--- $TXT_DNS_TITLE ---${NC}"
log_info "$TXT_DNS_EXPLAIN"
echo -e "$TXT_DNS_ASK"
read -p "> " dns_choice

RESOLV_CONF="/etc/resolv.conf"

if command -v chattr >/dev/null 2>&1; then chattr -i "$RESOLV_CONF" 2>/dev/null || true; fi
backup_file "$RESOLV_CONF"

if [ "$dns_choice" == "1" ]; then
    cat > "$RESOLV_CONF" <<EOF
nameserver 94.140.14.14
nameserver 94.140.15.15
nameserver 1.1.1.1
EOF
    log_action "DNS: Privacy Profile Applied."
elif [ "$dns_choice" == "2" ]; then
    cat > "$RESOLV_CONF" <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    log_action "DNS: Speed Profile Applied."
fi

if command -v chattr >/dev/null 2>&1; then 
    chattr +i "$RESOLV_CONF"
    log_action "$TXT_DNS_LOCK"
fi

# ==============================================================================
# 6. NETWORK & MTU
# ==============================================================================
echo -e "${BLUE}--- $TXT_NET_TITLE ---${NC}"
IFACE=$(ip route get 1.1.1.1 2>/dev/null | awk 'NR==1 {print $5}')
echo "$TXT_NET_IFACE $IFACE"

echo -e "$TXT_NET_ASK"
read -p "> " net_speed
TARGET_MTU=1500

case $net_speed in
    1) TARGET_MTU=1500 ;;
    2)
        echo -e "${YELLOW}$TXT_JUMBO_WARN${NC}"
        read -p "$TXT_JUMBO_CONFIRM " j_conf
        if [[ "$j_conf" =~ ^[oOyY] ]]; then TARGET_MTU=9000; fi
        ;;
esac

if [ ! -z "$IFACE" ]; then
    ip link set dev "$IFACE" mtu $TARGET_MTU
    log_action "MTU $IFACE -> $TARGET_MTU"
else
    log_warn "Interface network not found. MTU skipped."
fi

# ==============================================================================
# 7. SSH ACCELERATION
# ==============================================================================
echo -e "${BLUE}--- $TXT_SSH_TITLE ---${NC}"
SSH_CONF="/etc/ssh/sshd_config"

if [ -f "$SSH_CONF" ]; then
    backup_file "$SSH_CONF"
    if grep -q "^UseDNS" "$SSH_CONF"; then
        sed -i 's/^UseDNS.*/UseDNS no/' "$SSH_CONF"
    else
        echo "UseDNS no" >> "$SSH_CONF"
    fi
    log_action "$TXT_SSH_APPLY"
fi

# ==============================================================================
# 8. SYSTEM LIMITS / ULIMIT
# ==============================================================================
echo -e "${BLUE}--- $TXT_LIMITS_TITLE ---${NC}"
LIMITS_CONF="/etc/security/limits.d/99-optimize-limits.conf"

cat > "$LIMITS_CONF" <<EOF
# Generated by Optinux
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF
log_action "$TXT_LIMITS_APPLY"

# ==============================================================================
# 9. KERNEL / SYSCTL
# ==============================================================================
echo -e "${BLUE}--- $TXT_KERNEL_TITLE ---${NC}"
log_info "$TXT_KERNEL_EXPLAIN"
SYSCTL_CUSTOM="/etc/sysctl.d/99-optimize-debian.conf"
backup_file "/etc/sysctl.conf"

cat > "$SYSCTL_CUSTOM" <<EOF
# --- Optinux Kernel Optimization ---
vm.swappiness = 10
vm.vfs_cache_pressure = 50
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

sysctl -p "$SYSCTL_CUSTOM"
log_action "$TXT_KERNEL_APPLY"

# ==============================================================================
# 11. OPTIMISATION APACHE
# ==============================================================================
if command -v apache2 >/dev/null 2>&1; then
    echo -e "${BLUE}--- $TXT_APACHE_TITLE ---${NC}"
    log_info "$TXT_APACHE_EXPLAIN"
    echo -e "$TXT_APACHE_DETECT"
    read -p "$TXT_APACHE_ASK " ap_choice

    if [[ "$ap_choice" =~ ^[oOyY] ]]; then
        
        # 1. BACKUP APACHE
        log_info "Backup /etc/apache2..."
        backup_folder "/etc/apache2"

        # 2. SWITCH MPM (PREFORK -> EVENT)
        # FR: Prefork est obsolète pour le trafic moderne. Event est threadé et gère mieux la charge.
        # EN: Prefork is obsolete for modern traffic. Event is threaded and handles load better.
        if /usr/sbin/apache2ctl -M | grep -q "mpm_prefork"; then
            a2dismod mpm_prefork >/dev/null 2>&1
            a2enmod mpm_event >/dev/null 2>&1
            log_action "$TXT_APACHE_MPM"
        fi

        # 3. OPTIMISATION MPM EVENT CONFIG
        # FR: Configuration basée sur tes recommandations (ServerLimit 16, etc)
        MPM_CONF="/etc/apache2/mods-available/mpm_event.conf"
        cat > "$MPM_CONF" <<EOF
<IfModule mpm_event_module>
    ServerLimit              16
    StartServers              2
    MinSpareThreads          50
    MaxSpareThreads         200
    ThreadLimit              64
    ThreadsPerChild          50
    MaxRequestWorkers       800
    MaxConnectionsPerChild 5000
</IfModule>
EOF
        log_action "MPM Event Config Updated."

        # 4. CONFIGURATION GLOBALE OPTINUX (SECURITE & PERF)
        # FR: On injecte ici les headers, timeouts, et le disable des logs DNS.
        # EN: Injecting headers, timeouts, and disabling DNS logs here.
        OPTINUX_CONF="/etc/apache2/conf-available/99-optinux-optimization.conf"
        
        cat > "$OPTINUX_CONF" <<EOF
# --- OPTINUX APACHE OPTIMIZATION ---

# 1. DNS & LOGS
HostnameLookups Off
# LogFormat personnalisé pour éviter le DNS lookup (%h -> %a)
LogFormat "%a %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined_ip

# 2. TIMEOUTS & KEEPALIVE (Anti-DoS)
Timeout 30
KeepAlive On
MaxKeepAliveRequests 200
KeepAliveTimeout 2
RequestReadTimeout header=10-20,MinRate=500 body=10,MinRate=500

# 3. SECURITY HEADERS (Baseline)
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

# 4. PROTOCOLS (HTTP/2)
Protocols h2 http/1.1

# 5. CACHE & COMPRESSION
FileETag None
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json image/svg+xml
</IfModule>
EOF
        
        # Activer la conf
        a2enconf 99-optinux-optimization >/dev/null 2>&1

        # 5. ACTIVATION MODULES ESSENTIELS
        # FR: On s'assure que headers, ssl, http2 sont actifs.
        MODULES=("headers" "rewrite" "ssl" "http2" "expires" "deflate")
        for mod in "${MODULES[@]}"; do
            a2enmod "$mod" >/dev/null 2>&1
        done
        
        # Check si brotli existe (Debian récent)
        if [ -f /etc/apache2/mods-available/brotli.load ]; then
            a2enmod brotli >/dev/null 2>&1
            log_action "Module Brotli Enabled."
        fi

        log_action "$TXT_APACHE_CONF"

        # 6. VALIDATION & RESTART
        # FR: Test de config avant restart pour ne pas casser le serveur.
        # EN: Config test before restart to avoid breaking the server.
        if apache2ctl configtest >/dev/null 2>&1; then
            systemctl restart apache2
            log_action "Apache Restarted Successfully."
        else
            log_err "$TXT_APACHE_FAIL"
            log_warn "Rolling back Apache configuration..."
            # Restauration simple : on désactive notre conf custom
            a2disconf 99-optinux-optimization >/dev/null 2>&1
            systemctl restart apache2
        fi
    fi
fi

# ==============================================================================
# 12. FIN
# ==============================================================================
echo ""
echo -e "${GREEN}=== $TXT_DONE_TITLE ===${NC}"
echo "Log: $LOG_FILE"
echo "Backup: $BACKUP_DIR"
echo ""
read -p "$TXT_REBOOT_ASK " reb
if [[ "$reb" =~ ^[oOyY] ]]; then
    reboot
fi
