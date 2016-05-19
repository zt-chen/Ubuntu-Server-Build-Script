
#################################################
# this is the script for setting up omniauth for gitlab-ce
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
Path_gitlabrb=/etc/gitlab/gitlab.rb

echo -e "To enable omniAuth for github, firstly you need to get you app key from github.com"
question "Do you want to enable omniAuth to connect to github?"
confGitOmni=$?
if [ $confGitOmni -eq 1 ]; then
	echo -e "Please input your app_id get form github.com"
	read omni_app_id
	echo -e "Please input your app_secret get form github.com"
	read omni_app_secret
fi


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

	# restart gitlab
	sudo gitlab-ctl reconfigure
	sudo gitlab-ctl restart
fi
