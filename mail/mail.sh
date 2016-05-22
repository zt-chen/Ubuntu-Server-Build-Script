# script for setting up postfix + dovecot 
# tutorial & reference :
# https://www.digitalocean.com/community/tutorials/how-to-configure-a-mail-server-using-postfix-dovecot-mysql-and-spamassassin
# include helper functions
source helper.sh

echo -e "We need you MySql database root password for setting up DB"
echo -e "Please input you MySql root password here:"
read MySqlPwd
echo -e "What password do you want to setup for mail DB user?"
read mailDBPwd

echo -e "Please input your domain name: abc.com"
read domainName

echo -e "Please input the FDNQ you want to use for you mail server"
read mailFDNQ

echo -e "Please input a username for you email"
read mailUserName

echo -e "Please input the password for this user"
read mailUserPwd

echo -e "Please input the path to ssl_cert you want to use for mail"
read ssl_cert

echo -e "Please input the path to ssl private key you want to use for mail"
read ssl_priv

# Install Packges
sudo apt-get install postfix postfix-mysql dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql
# install mysql
sudo apt-get install mysql-server libapache2-mod-auth-mysql php5-mysql
# for the sake of security
sudo mysql_secure_installation

# Create servermail database
mysql --user=root --password=$MySqlPwd -e 'CREATE DATABASE servermail;'

Str1='GRANT ALL PRIVILEGES ON servermail.* TO "usermail"@"localhost" IDENTIFIED BY "'
Str2='";'
Query="$Str1$mailDBPwd$Str2"
mysql --user=root --password=$MySqlPwd -e "$Query"
# 3.FLUSH PRIVILEGES;
mysql --user=root --password=$MySqlPwd -e 'FLUSH PRIVILEGES;'

mysql --user=root --password=$MySqlPwd < ./postfix/db.sql 

# Virtual Domains
Query="INSERT INTO \`servermail\`.\`virtual_domains\`
(\`id\` ,\`name\`)
VALUES
(\"1\", \"$domainName\"),
(\"2\", \"$mailFDNQ\");"
echo $Query > ./tmp/query.sql
mysql --user=root --password=$MySqlPwd servermail < ./tmp/query.sql

# Virtual Emails
Query="INSERT INTO \`servermail\`.\`virtual_users\`
(\`id\`, \`domain_id\`, \`password\` , \`email\`)
VALUES
('1', '2', ENCRYPT('$mailUserPwd', CONCAT('\$6$', SUBSTRING(SHA(RAND()), -16))), '$mailUserName@$mailFDNQ');"
echo $Query > ./tmp/query.sql
mysql --user=root --password=$MySqlPwd servermail < ./tmp/query.sql


# Virtual Aliases
#Query=INSERT INTO `servermail`.`virtual_aliases`
#(`id`, `domain_id`, `source`, `destination`)
#VALUES
#('1', '1', 'alias@example.com', 'email1@example.com');

# Configure Postfix
# configure main.cf
sudo mv /etc/postfix/main.cf /etc/postfix/main.cf.bak
cp ./postfix/main.cf ./tmp

replaceFQDN $fqdn ./tmp/main.cf
replaceSSL $ssl_cert $ssl_priv ./tmp/main.cf

sudo chmod g-w ./tmp/main.cf
sudo cp ./tmp/main.cf /etc/postfix/

# configure mysql-virtual-mailbox-domains.cf
cp ./postfix/mysql-virtual-mailbox-domains.cf ./tmp
replacePWD $mailDBPwd ./tmp/mysql-virtual-mailbox-domains.cf

sudo chmod g-w ./tmp/mysql-virtual-mailbox-domains.cf
sudo cp ./tmp/mysql-virtual-mailbox-domains.cf /etc/postfix/


# configure mysql-virtual-mailbox-maps.cf
cp ./postfix/mysql-virtual-mailbox-maps.cf ./tmp
replacePWD $mailDBPwd ./tmp/mysql-virtual-mailbox-maps.cf

sudo chmod g-w ./tmp/mysql-virtual-mailbox-maps.cf
sudo cp ./tmp/mysql-virtual-mailbox-maps.cf /etc/postfix/

# configure mysql-virtual-alias-maps.cf
cp ./postfix/mysql-virtual-alias-maps.cf ./tmp
replacePWD $mailDBPwd ./tmp/mysql-virtual-alias-maps.cf

sudo chmod g-w ./tmp/mysql-virtual-alias-maps.cf
sudo cp ./tmp/mysql-virtual-alias-maps.cf /etc/postfix

# configure master.cf to enable port 587 for securely connection with email clients

sudo cp /etc/postfix/master.cf /etc/postfix/master.cf.bak
sudo cp ./postfix/master.cf /etc/postfix

# restart service
sudo service postfix restart

##################
# Configure Dovecot

p_dovecot=/etc/dovecot
# backup files
sudo mv /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.bak
sudo mv /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.bak
sudo mv /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.bak
sudo mv /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.bak
sudo mv /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.bak
sudo mv /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.bak

cp -r ./dovecot ./tmp/

# modify dovecot.conf
sudo cp ./tmp/dovecot/dovecot.conf $p_dovecot/

# modified 10-mail.conf
sudo cp ./tmp/dovecot/conf.d/10-mail.conf $p_dovecot/conf.d/

# verify permissions
sudo mkdir -p /var/mail/vhosts/$domainName
sudo mkdir -p /var/mail/vhosta/$mailFDNQ

# Create a vmail user and group with an id of 5000
sudo groupadd -g 5000 vmail 
sudo useradd -g vmail -u 5000 vmail -d /var/mail

# change the owner of the /var/mail folder to the vmail user.
sudo chown -R vmail:vmail /var/mail

# modified 10-auth.conf
sudo cp ./tmp/dovecot/conf.d/10-auth.conf $p_dovecot/conf.d/

# modified auth-sql.conf.ext
sudo cp ./tmp/dovecot/conf.d/auth-sql.conf.ext $p_dovecot/conf.d/

#modified dovecot-sql.conf.ext
replacePWD $mailDBPwd ./tmp/dovecot/dovecot-sql.conf.ext
sudo cp ./tmp/dovecot/dovecot-sql.conf.ext $p_dovecot/

# Change the owner and the group of the dovecot folder to vmail user:
sudo chown -R vmail:dovecot /etc/dovecot
sudo chmod -R o-rwx /etc/dovecot 

# modified 10-master.conf
sudo cp ./tmp/dovecot/conf.d/10-master.conf $p_dovecot/conf.d/

# modified 10-ssl.conf
replaceSSL $ssl_cert $ssl_priv ./tmp/dovecot/conf.d/10-ssl.conf
sudo cp ./tmp/dovecot/conf.d/10-ssl.conf $p_dovecot/conf.d/

sudo chown -R vmail:dovecot /etc/dovecot/conf.d/

# restart dovecot 
sudo service dovecot restart

#########################
# configure SpamAssassin
# sudo apt-get install spamassassin spamc
# sudo adduser spamd --disabled-login

