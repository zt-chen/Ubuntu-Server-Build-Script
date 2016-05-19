#################################################
# this is the script for installing wordpress
# Author:	Zitai Chen
# Email:	chenzitai@139.com
# Date:		19/05/2016
# Copyright Zitai Chen
# 
#################################################

# Helper function for question
question() {
    echo -e "$1 (y/n)"
    read userinput < /dev/tty
    if [ "$userinput" == "y" ]; then
        return 1
    else
        return 0
    fi
}
###############################################
# Install question
echo -e "Wordpress depend on Mysql and PHP5, to continue, we will first install mysql and PHP5"
echo -e "Please remebmer the password you setup for mysql!!"
question "Do you want to install WordPress?"
installWordpress=$?

# install apache2
sudo apt-get install apache2

###################
# Install mysql

# install mysql
sudo apt-get install mysql-server libapache2-mod-auth-mysql php5-mysql
#sudo apt-get install mysql-server

# for the sake of security
sudo mysql_secure_installation

#####################
# Install PHP5
sudo apt-get install php5 libapache2-mod-php5 php5-mcrypt

# Add php5 wo directory index (activated by default)
# sudo vim /etc/apache2/mods-enabled/dir.conf
# <IfModule mod_dir.c>
#   DirectoryIndex index.php index.html index.cgi index.pl index.php index.xhtml index.htm
# </IfModule>

# Enable extensions
# for mysql


###################
# Install WordPress

if [ $installWordpress -eq 1 ]; then
    echo -e "We need you MySql database root password for setting up DB"
    echo -e "Please input you MySql root password here:"
    read MySqlPwd
    echo -e "What password do you want to setup for wordpress DB user?"
    read wordpressDBPwd
fi


if [ $installWordpress -eq 1 ]; then
    mkdir tmp
    # get package
    wget http://wordpress.org/latest.tar.gz -P ./tmp/

    # unzip
    tar -zxf tmp/latest.tar.gz -C ./tmp/

    # set up Mysql info when installing
    # Mysql SQL query 
    # 1.CREATE DATABASE wordpress;
    mysql --user=root --password=$MySqlPwd -e 'CREATE DATABASE wordpress;'
    # 2.GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"localhost" IDENTIFIED BY "password";
    # strcat these three strings because of ""
    Str1='GRANT ALL PRIVILEGES ON wordpress.* TO "wordpress"@"localhost" IDENTIFIED BY "'
    Str2='";'
    Query="$Str1$wordpressDBPwd$Str2"
    mysql --user=root --password=$MySqlPwd -e "$Query"
    # 3.FLUSH PRIVILEGES;
    mysql --user=root --password=$MySqlPwd -e 'FLUSH PRIVILEGES;'

    # move wordpress to html directory
    sudo mv ./tmp/wordpress /var/www/html
    # change the ownership of wordpress directory
    sudo chown www-data:www-data -R /var/www/html/wordpress

	rm -rf ./tmp

    echo -e "---------------------------------------------------------------"
    echo -e "Please writedown these information for you to setup Wordpress:"
    echo -e "wordpress DB name: wordpress"
    echo -e "wordpress DB username: wordpress"
    echo -e "wordpress DB password: $wordpressDBPwd"
    echo -e "Please proceed to http(s)://yourhostname/wordpress to continue setup"
    echo -e "Press Enter to continue..."
    echo -e "---------------------------------------------------------------"
    read temp
fi
