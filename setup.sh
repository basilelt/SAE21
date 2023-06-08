## penser à changer ip dans netword et dans squidguard lorsqu'en prod et retirer open-vm-tools

apt remove network-manager -y
systemctl enable systemd-networkd
systemctl daemon-reload

rm /etc/systemd/network/eth.network
cat > /etc/systemd/network/eth.network <<EOF
[Match]
Name=e*

[Network]
DHCP=yes

[DHCP]
UseDNS=true
EOF
systemctl restart systemd-networkd
dhclient -r

rm /etc/apt/sources.list
cat > /etc/apt/sources.list <<EOF
# bullseye
deb http://deb.debian.org/debian/ bullseye main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye main non-free contrib

# bullseye-updates, previously known as 'volatile
deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-updates main contrib non-free

# bullseye-backports, previously on backports, debian.org
deb http://deb.debian.org/debian/ bullseye-backports main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-backports main contrib non-free

# bullseye-proposed-updates
deb http://deb.debian.org/debian/ bullseye-proposed-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bullseye-proposed-updates main contrib non-free

# debian security
deb http://deb.debian.org/debian-security/ bullseye-security main contrib non-free
deb-src http:deb.debian.org/debian-security/ bullseye-security main contrib non-free
EOF

apt update -y && apt upgrade -y && apt full-upgrade -y && apt dist-upgrade -y && apt autoclean -y && apt clean -y && apt autoremove -y
apt install -y rsync openssh-client proftpd proftpd-basic apache2 squid putty dsniff openssl squidguard sshd
apt install -y open-vm-tools

rm /etc/systemd/network/eth.network
cat > /etc/systemd/network/eth.network <<EOF
[Match]
Name=e*

[Network]
Address=172.16.155.252/22
Gateway=172.16.155.254
DNS=8.8.8.8 1.1.1.1
EOF
systemctl restart systemd-networkd
dhclient -r

systemctl start proftpd
systemctl enable proftpd

openssl req -x509 -newkey rsa:1024 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -nodes -days 365
chmod 600 /etc/ssl/private/proftpd.key
chmod 600 /etc/ssl/certs/proftpd.crt

mkdir /home/ftpuser
groupadd -f ftpuser
useradd -d /home/ftpuser -g ftpuser -p $(openssl passwd -1 toto) ftpuser
chown -R ftpuser:ftpuser /home/ftpuser

rm /etc/proftpd/proftpd.conf
cat > /etc/proftpd/proftpd.conf <<EOF
# Nom du serveur qui s'affiche
ServerName "FTP-G2-RT11"
# Serveur Autonome (ne pas modifier)
ServerType standalone
# Activer le serveur par défaut (Si pas de "VirtualHost")
DefaultServer on
# Est-ce qu'on a besoin d'un shell valide pour se connecter
RequireValidShell off
# Activer l'authentification PAM
AuthPAM off
AuthPAMConfig ftp
 
# Port d'écoute (21 par défaut)
Port 21
 
# Permissions d'un dossier ou d'un fichier créé via FTP
Umask 022
 
# Nombre de connexions simultanées au FTP
MaxInstances 30
 
# Lancer le démon ftp sous cet utilisateur et groupe
User ftpuser
Group ftpuser
 
# Racine du FTP ( [b]~[/b] correspond au fait que l'utilisateur est cloisonné dans son dossier personnel)
DefaultRoot ~
AuthUserFile /etc/proftpd/ftpd.passwd
AuthGroupFile /etc/proftpd/ftpd.group
AuthOrder mod_auth_file.c

# Generally files are overwritable.
AllowOverwrite on
 
# Désactiver la commande CHMOD via le FTP
<Limit SITE_CHMOD>
  DenyAll
</Limit>
 
# Exemple de dossier anonyme sans possibilité d'uploader
<Anonymous ~share>
  User ftpuser
  Group ftpuser
 
  # Possibilité de se connecter avec l'utilisateurs "anonymous".
  UserAlias anonymous
 
  # Limiter le nombre de connexions anonymes
  MaxClients 10
 
  # Désactiver la commande WRITE (d'écriture) pour les utilisateurs anonymes
  <Limit WRITE>
    DenyAll
  </Limit>
</Anonymous>

Include /etc/proftpd/tls.conf
EOF

cat > /etc/proftpd/tls.conf <<EOF
TLSRSACertificateFile /etc/ssl/certs/proftpd.crt
TLSRSACertificateKeyFile /etc/ssl/private/proftpd.key
TLSEngine on
TLSLog /var/log/proftpd/tls.log
TLSProtocol SSLv23
TLSRequired on
TLSOptions NoCertRequest EnableDiags NoSessionReuseRequired
TLSVerifyClient off
EOF

sudo -u ftpuser mkdir /home/ftpuser/antoine && mkdir /home/ftpuser/cathy
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=antoine --uid=61 --gid=60 --home=/home/ftpuser/antoine/ --shell=/bin/false
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=antoine --change-password toto

ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=cathy --uid=61 --gid=61 --home=/home/ftpuser/cathy/ --shell=/bin/false
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=cathy --change-password toto

systemctl restart proftpd

sh /usr/share/doc/apache2/examples/setup-instance test

rm /etc/apache2-test/sites-enabled/000-default.conf
cat > /etc/apache2-test/sites-enabled/000-default.conf <<EOF
<VirtualHost *:8080>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
EOF

rm /etc/apache2-test/ports.conf
cat > /etc/apache2-test/ports.conf <<EOF
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default
# This is also true if you have upgraded from before 2.2.9-3 (i.e. from
# Debian etch). See /usr/share/doc/apache2.2-common/NEWS.Debian.gz and
# README.Debian.gz

Listen 8080

<IfModule mod_ssl.c>
    # If you add NameVirtualHost *:443 here, you will also have to change
    # the VirtualHost statement in /etc/apache2/sites-available/default-ssl
    # to <VirtualHost *:443>
    # Server Name Indication for SSL named virtual hosts is currently not
    # supported by MSIE on Windows XP.
    Listen 443
</IfModule>

<IfModule mod_gnutls.c>
    Listen 443
</IfModule>
EOF

systemctl enable apache2@test
systemctl daemon-reload
systemctl start apache2@test

cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
rm /etc/squid/squid.conf
cat > /etc/squid/squid.conf <<EOF
acl admin_vlan src 172.16.144.0/22
acl user_vlan src 172.16.148.0/22
acl port_8080 port 8080

http_access allow admin_vlan
http_access allow user_vlan !port_8080

http_port 3128
http_port 3129 intercept

url_rewrite_program /usr/bin/squidGuard # This line specifies the location of the SquidGuard program, which is used to rewrite URLs based on certain conditions.
url_rewrite_children 5 # This line specifies the number of SquidGuard processes that will be spawned to handle URL rewriting.
url_rewrite_access allow restricted_vlan port_8080 # This line specifies that URL rewriting is allowed for requests coming from the restricted VLAN and trying to access port 8080.
url_rewrite_access deny all # This line specifies that URL rewriting is denied for all other requests.

redirector_bypass on
EOF

cat > /etc/squidguard/squidGuard.conf <<EOF
# SquidGuard configuration file

# Define an ACL for the user VLAN
acl {
    user_vlan {
        src 172.16.148.0/22
    }
}

# Redirect requests from the user VLAN to port 80
src user_vlan {
    redirect http://172.16.155.253:80/
}
EOF

squidGuard -C all
systemctl restart squid
