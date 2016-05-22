# !/bin/bash
source helper.sh
# update system
echo -e "To continue, I will upgrade your system first."
echo -e "Continue? (y/n)"
read userinput < /dev/tty
if [ "$userinput" != "y" ]; then
    exit 1
fi
sudo apt-get update
sudo apt-get upgrade
########################################################
# Hostname: 
# etc/hosts 127.0.0.1 eu.chenzitai.com eu.localhost
# etc/hostname eu
v_hostname="www"
v_hosts="www.chenzitai.com localhost"

userinput="n"   # For user input

# update hostname
sudo service hostname restart
# show FQDN 
fqdn=`hostname -f`
echo -e "Your fully qualified domain name is: $fqdn"
echo -e "If this is not right, please change it before continue."
echo -e "Continue? (y/n)"
read userinput < /dev/tty
if [ "$userinput" != "y" ]; then
    exit 1
fi

#######################################################
# Install apache2
installQ apache2
ret=$?

if [ $ret -eq 1 ]; then
    sudo apt-get install apache2
fi

#######################################################
# install gitlab-ce
# Start of install questions for gitlab-ce
echo -e "If you install this, nginx, postgresql and postfix will also be installed."
installQ gitlab-ce
installGitlab=$?

if [ $installGitlab -eq 1 ]; then
    echo "Please input the FDNQ you want gitlab to run with:"
    read gitfqdn
    question "Are you in China?"    # Check if user is in China
    inChina=$?
    question "Do you want to use apache2(need to be installed before this) instead of nginx?"
    useApache2=$?
    if [ $useApache2 -eq 1 ]; then
        # ask for apache2 user name
        apacheUserName="www-data"
        echo -e "Is your apache2 username $apacheUserName? If not, please put your user name here."
        read temp
        if [ ! -z $temp ]; then
            apacheUserName=$temp
        fi
        # ask for apache version
        question "Are you running apache 2.4? y for 2.4, n for 2.2"
        apacheVersion=$?    # 1 for 2.4, 0 for 2.2
        question "Do you want to configure ssl for gitlab?"
        gitssl=$?
        if [ $gitssl -eq 1 ]; then
            echo -e "Please input the path to ssl_cert you want to use for gitlab"
            read ssl_cert

            echo -e "Please input the path to ssl private key you want to use for gitlab"
            read ssl_priv

            echo -e "Please input the path to CA file"
            read ssl_ca
        fi
    fi
    # Configure mail for gitlab-ce
    echo "This will configure gitlab to use gmail to reply by email."
    question "Do you want to configure reply by E-Mail for gitlab? "
    confGitMail=$?
    if [ $confGitMail -eq 1 ]; then
        confirm=0
        while [ $confirm -ne 1 ]
        do
            # Get user input
            echo -e "Please input your email address:"
            read EmailAddr < /dev/tty
            echo -e "Please input your email password:"
            read EmailPwd < /dev/tty
            Email_UN=`echo "$EmailAddr" | awk -F '@' '{print $1}'`
            # Double check
            echo -n "Email address: "
            echo $EmailAddr
            echo -n "Email password: "
            echo $EmailPwd
            question "Are these configurations for email right? "
            confirm=$?
        done
    fi
    # configure omniAuth for gitlab and github
    echo -e "To enable omniAuth for github, firstly you need to get you app key from github.com"
    question "Do you want to enable omniAuth to connect to github?"
    confGitOmni=$?
    if [ $confGitOmni -eq 1 ]; then
        echo -e "Please input your app_id get form github.com"
        read omni_app_id
        echo -e "Please input your app_secret get form github.com"
        read omni_app_secret
    fi
    # End of install questions for gitlab-ce

    # install gitlab-ce
    Path_gitlabrb=/etc/gitlab/gitlab.rb
    sudo service apache2 stop       # stop apache2 for a while to avoid confiltion
    # Install and configure the necessary dependencies
    sudo apt-get install curl openssh-server ca-certificates postfix

    # Add the GitLab package server and install the package
    if [ $inChina -eq 1 ]; then # If user is in China, use a mirror
        curl https://packages.gitlab.com/gpg.key 2> /dev/null | sudo apt-key add - &>/dev/null
        sudo echo "deb https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/ubuntu trusty main" >> /etc/apt/sources.list.d/gitlab-ce.list
        sudo apt-get update
    else
        curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
    fi
    sudo apt-get install gitlab-ce

    sudo sed -i "s/$fdnq/$gitfqdn/g" $Path_gitlabrb
    # Configure and start GitLab


    # Use apache2 instead of nginx
    # see http://docs.gitlab.com/omnibus/settings/nginx.html#using-a-non-bundled-web-server
    if [ $useApache2 -eq 1 ]; then
        # Disable nginx
        sudo cp $Path_gitlabrb /etc/gitlab/gitlab.rb.bak
        echo "nginx['enable'] = false" | sudo tee --append $Path_gitlabrb > /dev/null
        # Enable apache2 as server for gitlab
        echo "web_server['external_users'] = ['$apacheUserName']" | sudo tee --append $Path_gitlabrb > /dev/null
        echo "gitlab_workhorse['listen_network'] = \"tcp\"" | sudo tee --append $Path_gitlabrb > /dev/null
        echo "gitlab_workhorse['listen_addr'] = \"127.0.0.1:8181\"" | sudo tee --append $Path_gitlabrb > /dev/null
        # Add apache2 reconfigure file for gitlab
        # echo "Suppose you are running apache 2.4, if not, goto https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache to download the right apache conf"
        if [ $apacheVersion -eq 1 ]; then
            if [ $gitssl -eq 1 ]; then #user want ssl
                sudo a2enmod ssl
                sudo a2enmod headers
                sudo cp ./gitlab-apache/gitlab-omnibus-ssl-apache24.conf /etc/apache2/sites-available/
                replaceFQDN $gitfqdn /etc/apache2/sites-available/gitlab-omnibus-ssl-apache24.conf 
                replaceSSLCA $ssl_cert $ssl_priv $ssl_ca /etc/apache2/sites-available/gitlab-omnibus-ssl-apache24.conf 
                sudo sed -i "s|http://$fqdn|https://$gitfqdn|g" /etc/gitlab/gitlab.rb
                sudo ln -s ../sites-available/gitlab-omnibus-ssl-apache24.conf /etc/apache2/sites-enabled/gitlab.conf
            else
                sudo cp ./gitlab-apache/gitlab-omnibus-apache24.conf /etc/apache2/sites-available/

                replaceFQDN $gitfqdn /etc/apache2/sites-available/gitlab-omnibus-apache24.conf
                sudo ln -s ../sites-available/gitlab-omnibus-apache24.conf /etc/apache2/sites-enabled/gitlab.conf
            fi
        else
            echo "This script doesn't not support apache 2.2 yet, plaese setup apache manually."
        fi

        # enable proxy for apache2 required by conf
        sudo a2enmod proxy_http
        # enable rewrite engine for apache2 required by conf
        sudo a2enmod rewrite
        # Create log directory specified by conf file
        sudo mkdir -p /var/log/httpd/logs
        sudo service apache2 start
    fi
    # replace fqdn using gitfqdn for repo path
    sudo sed -i "s|$fqdn|$gitfqdn|g" /etc/gitlab/gitlab.rb
    # Configure mail for gitlab-ce
    if [ $confGitMail -eq 1 ]; then
        # modify the configuration file for email

        cp ./gitlab-mail/Gmail.mconf ./tmp/mail.conf
        sed -i "s/YOUR_EMAIL_ADDRESS/$EmailAddr/g" ./tmp/mail.conf
        sed -i "s/YOUR_EMAIL_PASSWORD/$EmailPwd/g" ./tmp/mail.conf
        sed -i "s/YOUR_EMAIL_NAME/$Email_UN/g" ./tmp/mail.conf
        # add configuration to gitlab.rb
        cat tmp/mail.conf | sudo tee --append $Path_gitlabrb > /dev/null
    fi

    # Configure omniAuth for gitlab-ce
    if [ $confGitOmni -eq 1 ]; then
        # enalbe omniAuth in gitlab.rb
        echo "# Enable omniAuth" | sudo tee --append $Path_gitlabrb > /dev/null
        echo "gitlab_rails['omniauth_enabled'] = true" | sudo tee --append $Path_gitlabrb > /dev/null
        # modify the temp gitlab configure file
        cp ./gitlab-omniauth/github.omni ./tmp/github.omni
        sed -i "s/APP_ID/$omni_app_id/g" ./tmp/github.omni
        sed -i "s/APP_SECRET/$omni_app_secret/g" ./tmp/github.omni
        # add gitlab configuration to gitlab.rb
        cat ./tmp/github.omni | sudo tee --append $Path_gitlabrb > /dev/null

    fi
    # restart service
    sudo gitlab-ctl reconfigure
    sudo gitlab-ctl restart
    sudo gitlab-ctl stop mailroom
    sudo gitlab-ctl start mailroom
fi




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


#######################################################
# Install WordPress
question "Do you want to install WordPress?"
installWordpress=$?
if [ $installWordpress -eq 1 ]; then
    echo -e "We need you MySql database root password for setting up DB"
    echo -e "Please input you MySql root password here:"
    read MySqlPwd
    echo -e "What password do you want to setup for wordpress DB user?"
    read wordpressDBPwd
fi


if [ $installWordpress -eq 1 ]; then

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



#For mosh
sudo apt-get install python-software-properties
sudo add-apt-repository ppa:keithw/mosh
sudo apt-get update
sudo apt-get install mosh

# remove tempory directory
sudo rm -rf ./tmp
