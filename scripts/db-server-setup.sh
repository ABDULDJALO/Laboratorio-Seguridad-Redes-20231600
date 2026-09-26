#!/bin/sh
# Configuracion de DB-Server (Alpine Linux)
# Laboratorio de Seguridad de Redes - Abdul Djalo - 2023-1600

# --- Red ---
echo 'auto lo' > /etc/network/interfaces
echo 'iface lo inet loopback' >> /etc/network/interfaces
echo 'auto eth0' >> /etc/network/interfaces
echo 'iface eth0 inet static' >> /etc/network/interfaces
echo '    address 172.23.16.131' >> /etc/network/interfaces
echo '    netmask 255.255.255.240' >> /etc/network/interfaces
echo '    gateway 172.23.16.129' >> /etc/network/interfaces

ip addr add 172.23.16.131/28 dev eth0
ip link set eth0 up
ip route add default via 172.23.16.129
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# --- Instalacion de MariaDB ---
apk update
apk add mariadb mariadb-client iptables

rc-service mariadb setup
rc-service mariadb start

# Permitir conexiones por red (no solo localhost)
sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf
# IMPORTANTE: quitar tambien "skip-networking" si esta presente
sed -i 's/^skip-networking/#skip-networking/' /etc/my.cnf.d/mariadb-server.cnf
rc-service mariadb restart

# --- Base de datos y usuario (solo accesible desde WEB-Server) ---
mysql -u root << 'EOF'
CREATE DATABASE labdb;
CREATE USER 'webuser'@'172.23.16.130' IDENTIFIED BY 'WebPass123!';
GRANT ALL PRIVILEGES ON labdb.* TO 'webuser'@'172.23.16.130';
FLUSH PRIVILEGES;
EOF

# --- IPTABLES: Web-Server solo puede hablar con DB-Server en el 3306 ---
# (Implementado a nivel de host porque el switch NM-16ESW emulado no
#  soporta ACLs de IP en direccion 'out' sobre puertos de acceso -
#  ver nota tecnica en running-configs/switch-c2691.txt)
iptables -A INPUT -p tcp -s 172.23.16.130 --dport 3306 -j ACCEPT
iptables -A INPUT -p tcp --dport 3306 -j DROP
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Verificacion
iptables -L -n
netstat -tlnp | grep 3306
