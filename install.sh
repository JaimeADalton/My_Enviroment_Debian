#/bin/bash

# INstalar paquetes basicos

apt install sudo curl wget vim nitrogen firefox-esr awesome lightdm nautilus hydra nmap nfs-common nfstrace nmon 

#modificar el archivo /etc/profile y .bashrc de jaimedalton y de root
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

mkdir -p /home/jaimedalton/.config/awesome
mkdir -p /root/.config/awesome

cp /etc/xdg/awesome/rc.lua /home/jaimedalton/.config/awesome
cp /etc/xdg/awesome/rc.lua /root/.config/awesome

