echo -e "Plesae input the password for mail DB"
read mailDBPwd

mysql --user=usermail --password=$mailDBPwd servermail -e "select * from virtual_users"

