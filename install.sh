#/bin/bash

# INstalar paquetes basicos
apt update
apt install sudo curl wget vim nitrogen firefox-esr awesome lightdm nautilus hydra nmap nfs-common nfstrace nmon alacritty i3lock remmina make cmake git

echo "modificar el archivo /etc/profile y .bashrc de jaimedalton y de root"
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
mkdir -p /home/user/{Downloads,Documents,Pictures,Music,Videos,Desktop}

mkdir -p /home/jaimedalton/.config/awesome
mkdir -p /root/.config/awesome

wget -O /home/jaimedalton/.config/awesome/rc.lua https://raw.githubusercontent.com/JaimeADalton/My_Enviroment_Debian/main/rc.lua

#Configurar sudoers para usuario principal NOPASSWD
#
