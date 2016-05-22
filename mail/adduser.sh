echo -e "Plesae input the password for mail DB"
read mailDBPwd

echo -e "Please input the FDNQ of this mail server"
read mailFDNQ

echo -e "Please input the usernam for your email"
echo -e "For example: play@example.com just put play here"
read mailUserName

echo -e "Please input the password for this user"
read mailUserPwd


mkdir ./tmp

# Virtual Emails
Query="INSERT INTO \`servermail\`.\`virtual_users\`
( \`domain_id\`, \`password\` , \`email\`)
VALUES
('2', ENCRYPT('$mailUserPwd', CONCAT('\$6$', SUBSTRING(SHA(RAND()), -16))), '$mailUserName@$mailFDNQ');"
echo $Query > ./tmp/query.sql
mysql --user=usermail --password=$mailDBPwd servermail < ./tmp/query.sql
rm -rf ./tmp
