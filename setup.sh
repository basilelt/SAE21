apt update -y && apt upgrade -y && apt full-upgrade -y && apt dist-upgrade -y && apt autoclean -y && apt clean -y && apt autoremove -y
apt install -y rsync openssh-client proftpd apache2 squid putty arpspoof openssl

systemctl start proftpd
systemctl enable proftpd

openssl req -x509 -newkey rsa:1024 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -nodes -days 365
chmod 600 /etc/ssl/private/proftpd.key
chmod 600 /etc/ssl/certs/proftpd.crt

adduser ftpuser
groupadd -f ftpuser
useradd -d /home/ftpuser -g ftpuser -p $(openssl passwd -1 toto) ftpuser

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

ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=antoine --uid=61 --gid=60 --home=/home/ftpuser/antoine/ --shell=/bin/false
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=antoine --change-password toto

ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=cathy --uid=61 --gid=61 --home=/home/ftpuser/cathy/ --shell=/bin/false
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=cathy --change-password toto

systemctl restart proftpd
