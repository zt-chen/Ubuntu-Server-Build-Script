
#################################################
# this is the script for installing some applications 
# for a brand new server
# Author:	Zitai Chen
# Email:	chenzitai@139.com
# Date:		19/05/2016
# Copyright Zitai Chen
# 
#################################################

installQ() {
    echo -e "Do you want to install $1? (y/n)"
    read userinput < /dev/tty
    if [ "$userinput" == "y" ]; then
        return 1
    else
        return 0
    fi
}

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
#######################################################
# Install mysql
echo -e "Mysql is essential for Wordpress."
echo -e "If you want to install Wordpress, please install Mysql."
echo -e "And Please remember the password you setup for Mysql."
question "Do you want to install Mysql? "
installMysql=$?
if [ $installMysql -eq 1 ]; then
    # install mysql
    sudo apt-get install mysql-server libapache2-mod-auth-mysql php5-mysql

    # for the sake of security
    sudo mysql_secure_installation
fi

#######################################################
# Install PHP5
echo -e "PHP5 is essential for Wordpress."
echo -e "If you want to install Wordpress, please install PHP5."
question "Do you want to install PHP5?"
installPHP=$?
if [ $installPHP -eq 1 ]; then
    sudo apt-get install php5 libapache2-mod-php5 php5-mcrypt
fi

# Add php5 wo directory index (activated by default)
# sudo vim /etc/apache2/mods-enabled/dir.conf
# <IfModule mod_dir.c>
#   DirectoryIndex index.php index.html index.cgi index.pl index.php index.xhtml index.htm
# </IfModule>

# Enable extensions
# for mysql

####################################################
# For china users need to add posgre sql deb
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update


#######################################################
# Install owncloud
echo -e "To continue, assume you are running ubuntu 14.04"
question "Do you want to install Owncloud?"
installOwncloud=$?

if [ $installOwncloud -eq 1 ]; then
    # Add key to apt
    sudo wget -nv https://download.owncloud.org/download/repositories/stable/xUbuntu_14.04/Release.key -O Release.key
    sudo apt-key add - < Release.key
    # Add repo
    sudo sh -c "echo 'deb http://download.owncloud.org/download/repositories/stable/xUbuntu_14.04/ /' >> /etc/apt/sources.list.d/owncloud.list"
    # update repo list and install
    sudo apt-get update
    sudo apt-get install owncloud

    # TODO: configure trusted domain and APCu
    echo -e "---------------------------------------------------------------"
    echo -e "Please proceed to http(s)://yourhostname/owncloud to continue setup"
    echo -e "If you have installed Mysql, you can choose to use mysql as db, and use root user to setup owncloud."
    echo -e "A owncloud user will be setup automatically by owncloud install wizard."
    echo -e "Press Enter to continue..."
    echo -e "---------------------------------------------------------------"
fi


