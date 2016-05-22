echo -e "Plesae input the password for mail DB"
read mailDBPwd

echo -e "Please input the full mail address you want to delete"
read mailAddr


mkdir ./tmp

# Virtual Emails
Query="delete from virtual_users where email='$mailAddr';"

echo $Query > ./tmp/query.sql
mysql --user=usermail --password=$mailDBPwd servermail < ./tmp/query.sql
