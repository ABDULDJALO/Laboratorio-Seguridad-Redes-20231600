#!/bin/sh
# Configuracion de WEB-Server (Alpine Linux)
# Laboratorio de Seguridad de Redes - Abdul Djalo - 2023-1600

# --- Red ---
echo 'auto lo' > /etc/network/interfaces
echo 'iface lo inet loopback' >> /etc/network/interfaces
echo 'auto eth0' >> /etc/network/interfaces
echo 'iface eth0 inet static' >> /etc/network/interfaces
echo '    address 172.23.16.130' >> /etc/network/interfaces
echo '    netmask 255.255.255.240' >> /etc/network/interfaces
echo '    gateway 172.23.16.129' >> /etc/network/interfaces

ip addr add 172.23.16.130/28 dev eth0
ip link set eth0 up
ip route add default via 172.23.16.129
echo 'nameserver 8.8.8.8' > /etc/resolv.conf

# --- Instalacion de nginx con HTTPS ---
apk update
apk add nginx openssl mariadb-client

mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/webserver.key \
    -out /etc/nginx/ssl/webserver.crt \
    -subj "/CN=172.23.16.130"

cat > /etc/nginx/http.d/default.conf << 'EOF'
server {
    listen 443 ssl;
    server_name 172.23.16.130;
    ssl_certificate /etc/nginx/ssl/webserver.crt;
    ssl_certificate_key /etc/nginx/ssl/webserver.key;
    root /var/www/html;
    index index.html;
}
EOF

mkdir -p /var/www/html
echo '<h1>WEB-Server - Laboratorio de Seguridad</h1>' > /var/www/html/index.html

nginx -t
rc-service nginx start

# --- Prueba de conexion a la base de datos (solo Web puede hacerlo) ---
mysql -h 172.23.16.131 -u webuser -pWebPass123! labdb \
    -e "SELECT 'Conexion exitosa Web-a-DB' AS resultado;"
