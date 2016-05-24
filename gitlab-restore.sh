num=$1
sudo chown -R git:git ./gitlab.bak
sudo chown -R root:root ./gitlab.bak/gitlab.etc
# restore repo backups
sudo cp -a ./gitlab.bak/backups/* /var/opt/gitlab/backups/

sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
sudo gitlab-rake gitlab:backup:restore BACKUP=$num
sudo gitlab-ctl start
sudo gitlab-rake gitlab:check SANITIZE=true
# restore secret files
sudo cp -a /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.old
sudo cp -a ./gitlab.bak/gitlab.etc/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json

sudo cp -a /etc/gitlab/gitlab.rb /etc/gitlab/gitlab.rb.old
sudo cp -a ./gitlab.bak/gitlab.etc/gitlab.rb /etc/gitlab/gitlab.rb

