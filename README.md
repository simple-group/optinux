# optinux
Optinux est un script Bash d'optimisation avancée conçu spécifiquement pour les serveurs basés sur Debian. Optinux is an advanced optimisation Bash script designed specifically for Debian-based servers.

Voici une proposition de documentation `README.md` pour ton dépôt GitHub, structurée de manière professionnelle pour mettre en valeur les fonctionnalités et la sécurité du script.

---

# 🐧 Optinux - Debian System Optimizer (Masterclass Edition)

**Optinux** est un script Bash d'optimisation avancée conçu spécifiquement pour les serveurs basés sur **Debian**. Il combine des réglages de performance du noyau (Kernel), des optimisations réseau, de la sécurité et un réglage fin pour le serveur Web Apache.

## 🇫🇷 Français

### 🚀 Fonctionnalités

Ce script automatise les meilleures pratiques d'administration système :

* **Priorisation par Rôle** : Ajuste la priorité CPU/IO selon l'usage (Web, Base de données, ou Stockage).
* **Optimisation Réseau** : Configuration du MTU (support Jumbo Frames) et activation du contrôle de congestion **TCP BBR**.
* **Nettoyage (Debloat)** : Désactivation des services inutiles sur un serveur (Bluetooth, Avahi, Cups).
* **Sécurité & DNS** : Configuration de DNS sécurisés/rapides et verrouillage du `resolv.conf`.
* **Accélération SSH** : Désactivation du Reverse DNS pour des connexions instantanées.
* **Masterclass Apache** :
* Passage de Prefork à **MPM Event**.
* Activation de **HTTP/2** et de la compression **Brotli/Deflate**.
* Injection de Headers de sécurité (HSTS, X-Frame-Options, etc.).


* **Fiabilité** : Création automatique de backups avant chaque modification majeure.

### 🛠️ Utilisation

1. Clonez le dépôt :
```bash
git clone https://github.com/simple-group/optinux.git
cd optinux

```


2. Rendez le script exécutable :
```bash
chmod +x optinux.sh

```


3. Lancez le script en tant que root :
```bash
sudo ./optinux.sh

```



---

## 🇺🇸 English

### 🚀 Key Features

This script automates advanced system administration best practices:

* **Role-Based Prioritization**: Adjusts CPU/IO priority based on server usage (Web, Database, or Storage).
* **Network Optimization**: MTU configuration (Jumbo Frames support) and **TCP BBR** congestion control activation.
* **System Debloat**: Disables unnecessary server services (Bluetooth, Avahi, Cups).
* **Security & DNS**: Configures fast/private DNS profiles and locks `resolv.conf`.
* **SSH Acceleration**: Disables Reverse DNS for near-instant login.
* **Apache Masterclass**:
* Switches from Prefork to **MPM Event**.
* Enables **HTTP/2** and **Brotli/Deflate** compression.
* Injects security headers (HSTS, X-Frame-Options, etc.).


* **Reliability**: Automatic backups are created before any major configuration change.

### 🛠️ How to use

1. Clone the repository:
```bash
git clone https://github.com/simple-group/optinux.git
cd optinux

```


2. Make the script executable:
```bash
chmod +x optinux.sh

```


3. Run the script as root:
```bash
sudo ./optinux.sh

```



---

### ⚠️ Avertissement / Disclaimer

**FR :** Ce script modifie des paramètres critiques du système. Bien que des sauvegardes soient effectuées, utilisez-le avec précaution sur des environnements de production.

**EN:** This script modifies critical system settings. While backups are performed, use it with caution in production environments.

**Author:** Brice Cornet - Simple CRM - [https://simple-crm.ai ](https://simple-crm.ai )


