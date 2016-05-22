
# Helper function for check user if want to install something
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
replaceSSL() {
    ssl_cert=$1
    ssl_priv=$2
    file=$3
    sudo sed -i "s|PATH_TO_CERT|$ssl_cert|g" $file 
    sudo sed -i "s|PATH_TO_KEY|$ssl_priv|g" $file 
}
replaceFQDN() {
    realfqdn=$1
    file=$2
    sudo sed -i "s/YOUR_SERVER_FQDN/$realfqdn/g" $file
}
replacePWD() {
    passwd=$1
    file=$2
    sudo sed -i "s/YOUR_PASSWORD/$passwd/g" $file
}
# show FQDN 
fqdn=`hostname -f`
# make tempory directory
mkdir tmp


