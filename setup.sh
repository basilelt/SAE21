## penser à changer ip dans netword et dans squidguard lorsqu'en prod et retirer open-vm-tools
## si machine physique changer networkd pour chaques interfaces

apt remove network-manager -y
systemctl enable systemd-networkd

cat > /etc/systemd/network/admin.network <<EOF
[Match]
Name=eth1

[Network]
DHCP=yes

[DHCP]
UseDNS=true
EOF
cp /etc/systemd/network/admin.network /etc/systemd/network/admin.network.save
systemctl restart systemd-networkd

apt update -y && apt upgrade -y && apt full-upgrade -y && apt dist-upgrade -y && apt autoclean -y && apt clean -y && apt autoremove -y
apt install -y rsync openssh-client proftpd proftpd-basic apache2 squid putty dsniff openssl squidguard proftpd-mod-crypto filezilla wireshark
apt install -y open-vm-tools-desktop open-vm-tools

rm /etc/systemd/network/admin.network
cat > /etc/systemd/network/admin.network <<EOF
[Match]
Name=eth1

[Network]
Address=172.16.147.252/22
Gateway=172.16.147.254
DNS=8.8.8.8 1.1.1.1
EOF

cat > /etc/systemd/network/user.network <<EOF
[Match]
Name=eth0

[Network]
Address=172.16.151.252/22
Gateway=172.16.151.254
DNS=8.8.8.8 1.1.1.1
EOF
systemctl restart systemd-networkd

systemctl start proftpd
systemctl enable proftpd

openssl req -x509 -newkey rsa:2048 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -nodes -days 365 -subj "/C=FR/ST=Haut-Rhin/L=Colmar/O=UHA/OU=RT/CN=g2.rt"
chown ftpuser:ftpuser /etc/ssl/private/proftpd.key
chown ftpuser:ftpuser /etc/ssl/certs/proftpd.crt
chmod 600 /etc/ssl/private/proftpd.key
chmod 600 /etc/ssl/certs/proftpd.crt

mkdir /home/ftpuser
mkdir /home/ftpuser/public
mkdir /home/ftpuser/antoine
mkdir /home/ftpuser/cathy

groupadd -f ftpuser
useradd -d /home/ftpuser -g ftpuser -p $(openssl passwd -1 toto) ftpuser
useradd -d /home/ftpuser/antoine -g ftpuser -p $(openssl passwd -1 toto) antoine
useradd -d /home/ftpuser/cathy -g ftpuser -p $(openssl passwd -1 toto) cathy

chown -R ftpuser:ftpuser /home/ftpuser
chown -R antoine:ftpuser /home/ftpuser/antoine
chown -R cathy:ftpuser /home/ftpuser/cathy

chmod -R 755 /home/ftpuser
chmod -R 770 /home/ftpuser/antoine/
chmod -R 770 /home/ftpuser/cathy/

echo '/bin/false' >> /etc/shells

echo -n "toto" | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name=antoine --uid=$(id -u antoine) --gid=$(id -g ftpuser) --home=/home/ftpuser/antoine/ --shell=/bin/false
echo -n "toto" | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name=cathy --uid=$(id -u cathy) --gid=$(id -g ftpuser) --home=/home/ftpuser/cathy/ --shell=/bin/false
echo -n "toto" | ftpasswd --stdin --passwd --file=/etc/proftpd/ftpd.passwd --name=ftpuser --uid=$(id -u ftpuser) --gid=$(id -g ftpuser) --home=/home/ftpuser --shell=/bin/false

rm /etc/proftpd/modules.conf
cat > /etc/proftpd/modules.conf <<EOF
#
# This file is used to manage DSO modules and features.
#

# This is the directory where DSO modules reside

ModulePath /usr/lib/proftpd

# Allow only user root to load and unload modules, but allow everyone
# to see which modules have been loaded

ModuleControlsACLs insmod,rmmod allow user root
ModuleControlsACLs lsmod allow user *

#This is required only if you need to set IdentLookups on
#LoadModule mod_ident.c

LoadModule mod_ctrls_admin.c

# Install proftpd-mod-crypto to use this module for TLS/SSL support.
LoadModule mod_tls.c
# Even these modules depend on the previous one
#LoadModule mod_tls_fscache.c
#LoadModule mod_tls_shmcache.c

# Install one of proftpd-mod-mysql, proftpd-mod-pgsql or any other
# SQL backend engine to use this module and the required backend.
# This module must be mandatory loaded before anyone of
# the existent SQL backeds.
#LoadModule mod_sql.c

# Install proftpd-mod-ldap to use this for LDAP support.
#LoadModule mod_ldap.c

#
# 'SQLBackend mysql' or 'SQLBackend postgres' (or any other valid backend) directives 
# are required to have SQL authorization working. You can also comment out the
# unused module here, in alternative.
#

# Install proftpd-mod-mysql and decomment the previous
# mod_sql.c module to use this.
#LoadModule mod_sql_mysql.c

# Install proftpd-mod-pgsql and decomment the previous 
# mod_sql.c module to use this.
#LoadModule mod_sql_postgres.c

# Install proftpd-mod-sqlite and decomment the previous
# mod_sql.c module to use this
#LoadModule mod_sql_sqlite.c

# Install proftpd-mod-odbc and decomment the previous
# mod_sql.c module to use this
#LoadModule mod_sql_odbc.c

# Install one of the previous SQL backends and decomment 
# the previous mod_sql.c module to use this
#LoadModule mod_sql_passwd.c

LoadModule mod_radius.c
LoadModule mod_quotatab.c
LoadModule mod_quotatab_file.c

# Install proftpd-mod-ldap to use this
#LoadModule mod_quotatab_ldap.c

# Install one of the previous SQL backends and decomment 
# the previous mod_sql.c module to use this
#LoadModule mod_quotatab_sql.c
LoadModule mod_quotatab_radius.c
# Install proftpd-mod-wrap module to use this
#LoadModule mod_wrap.c
LoadModule mod_rewrite.c
LoadModule mod_load.c
LoadModule mod_ban.c
LoadModule mod_wrap2.c
LoadModule mod_wrap2_file.c
# Install one of the previous SQL backends and decomment 
# the previous mod_sql.c module to use this
#LoadModule mod_wrap2_sql.c
LoadModule mod_dynmasq.c
LoadModule mod_exec.c
LoadModule mod_shaper.c
LoadModule mod_ratio.c
LoadModule mod_site_misc.c

# Install proftpd-mod-crypto to use this module for SFTP support.
#LoadModule mod_sftp.c
#LoadModule mod_sftp_pam.c

# Install one of the previous SQL backends and decomment 
# the previous mod_sql.c module to use this
#LoadModule mod_sftp_sql.c

LoadModule mod_facl.c
LoadModule mod_unique_id.c
LoadModule mod_copy.c
LoadModule mod_deflate.c
LoadModule mod_ifversion.c
LoadModule mod_memcache.c
# Install proftpd-mod-crypto to use this module for TLS/SSL support.
#LoadModule mod_tls_memcache.c

#LoadModule mod_redis.c
# Install proftpd-mod-crypto to use this module for TLS/SSL support.
#LoadModule mod_tls_redis.c
#LoadModule mod_wrap2_redis.c

#LoadModule mod_auth_otp.c

LoadModule mod_readme.c

# Install proftpd-mod-geoip to use the GeoIP feature
#LoadModule mod_geoip.c

# Install proftpd-mod-snmp to use the SNMP feature
#LoadModule mod_snmp.c

# keep this module the last one
LoadModule mod_ifsession.c
EOF

rm /etc/proftpd/proftpd.conf
cat > /etc/proftpd/proftpd.conf <<EOF
# Set the log level to "debug"
SysLogLevel debug

LoadModule mod_tls.c

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

DefaultAddress 172.16.151.252

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
AuthOrder mod_auth_file.c

# Généralement les fichiers sont overwritable.
AllowOverwrite on
 
# Désactiver la commande CHMOD via le FTP
<Limit SITE_CHMOD>
  DenyAll
</Limit>
 
# Dossier anonyme sans possibilité d'uploader
<Anonymous /home/ftpuser/public>
  User ftpuser
  Group ftpuser
 
  # Possibilité de se connecter avec l'utilisateurs "anonymous".
  UserAlias anonymous ftpuser
 
  # Limiter le nombre de connexions anonymes
  MaxClients 10
 
  # Désactiver la commande WRITE (d'écriture) pour les utilisateurs anonymes
  <Limit WRITE>
    DenyAll
  </Limit>
</Anonymous>

Include /etc/proftpd/user.conf
Include /etc/proftpd/tls.conf
EOF

cat > /etc/proftpd/user.conf <<EOF
<Directory /home/ftpuser/antoine>
  <Limit WRITE>
    AllowUser antoine
  </Limit>
</Directory>

<Directory /home/ftpuser/cathy>
  <Limit WRITE>
    AllowUser cathy
  </Limit>
</Directory>
EOF

cat > /etc/proftpd/tls.conf <<EOF
TLSEngine on
TLSLog /var/log/proftpd/tls.log
TLSProtocol TLSv1.2
TLSRSACertificateFile /etc/ssl/certs/proftpd.crt
TLSRSACertificateKeyFile /etc/ssl/private/proftpd.key
TLSRequired on
EOF

systemctl restart proftpd

sh /usr/share/doc/apache2/examples/setup-instance test

cp /var/www/html/index.html /var/www//html/save.html
rm /var/www/html/index.html
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
  <head>
    <title>PROD</title>
  </head>
  <body>
    <h1>PROD</h1>
    <p>Ceci est le site de prod</p>
  </body>
</html>
EOF

mkdir /var/www/html-test
cat > /var/www/html-test/index.html <<EOF
<!DOCTYPE html>
<html>
  <head>
    <title>TEST</title>
  </head>
  <body>
    <h1>TEST</h1>
    <p>Ceci est le site de test</p>
  </body>
</html>
EOF

rm /etc/apache2/sites-enabled/000-default.conf
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost 172.16.151.252:80>
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

rm /etc/apache2-test/sites-enabled/000-default.conf
cat > /etc/apache2-test/sites-enabled/000-default.conf <<EOF
<VirtualHost 172.16.147.252:8080>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html-test

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
systemctl restart apache2@test
systemctl restart apache2

cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
rm /etc/squid/squid.conf
cat > /etc/squid/squid.conf <<EOF
acl admin_vlan src 172.16.144.0/22
acl user_vlan src 172.16.148.0/22
acl port_8080 port 8080

http_access allow admin_vlan
http_access allow user_vlan

http_port 172.16.147.252:3128
http_port 172.16.147.252:3129 intercept

url_rewrite_program /usr/bin/squidGuard # This line specifies the location of the SquidGuard program, which is used to rewrite URLs based on certain conditions.
url_rewrite_children 5 # This line specifies the number of SquidGuard processes that will be spawned to handle URL rewriting.
url_rewrite_access allow user_vlan port_8080 # This line specifies that URL rewriting is allowed for requests coming from the restricted VLAN and trying to access port 8080.
url_rewrite_access deny all # This line specifies that URL rewriting is denied for all other requests.

redirector_bypass on
EOF

cat > /etc/squidguard/squidGuard.conf <<EOF
# SquidGuard configuration file

# Define the source for the user VLAN
src user_vlan {
    ip 172.16.148.0/22
}

# Define an ACL for the user VLAN
acl {
    user_vlan {
        pass !in-addr all
        redirect http://172.16.151.252:80/
    }
    default {
        pass all
    }
}
EOF

squidGuard -C all
systemctl restart squid
