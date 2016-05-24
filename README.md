# ServerScripts
Useful scripts for setting up a brand new server and install applications (Gitlab, wordpress, owncloud)

在ubuntu Server 14.04 上安装 gitlab wordpress owncloud 等应用的脚本

## 文件说明
* Server.sh   
  脚本主程序，包含GitLab, wordpress, mosh 安装及设置脚本

* wordpress.sh    
  用于安装Wordpress的脚本

* owncloud.sh  
  用于安装owncloud的脚本

* mailconf.sh   
  用于设置gitlab Email回复的脚本， 目前本脚本仅支出Gmail

* omniauth.sh   
  用于设置 gitlab omniauth的脚本， 目前本脚本仅支持GitHub
  需要在GitHub上先获取APPID等信息

* fiiinx 
  通过Fiinx进行服务器备份/还原/迁移

## 注意事项
在使用之前，请先设置好FQDN (Full Qualified Domain Name)
使用脚本设置时， 请记录好使用的密码，便于日后维护
