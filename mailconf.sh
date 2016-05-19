# !/bin/bash
#################################################
# this is the script for setting up mail for gitlab-ce
# Author:	Zitai Chen
# Email:	chenzitai@139.com
# Date:		19/05/2016
# Copyright Zitai Chen
# 
#################################################

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


#############################################
# Configure smtp for gitlab-ce
Path_gitlabrb=/etc/gitlab/gitlab.rb
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

if [ $confGitMail -eq 1 ]; then
	# modify the configuration file for email
	mkdir tmp
	cp ./gitlab-mail/Gmail.mconf ./tmp/mail.conf
	sed -i "s/YOUR_EMAIL_ADDRESS/$EmailAddr/g" ./tmp/mail.conf
	sed -i "s/YOUR_EMAIL_PASSWORD/$EmailPwd/g" ./tmp/mail.conf
	sed -i "s/YOUR_EMAIL_NAME/$Email_UN/g" ./tmp/mail.conf
    # add configuration to gitlab.rb
	cat tmp/mail.conf | sudo tee --append $Path_gitlabrb > /dev/null
    # restart service
	sudo gitlab-ctl reconfigure
	sudo gitlab-ctl stop mailroom
	sudo gitlab-ctl start mailroom
fi
