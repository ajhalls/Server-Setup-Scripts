#!/bin/bash

# Grab a password for MySQL Root
read -s -p "Enter the password that will be used for MySQL Root: " mysqlrootpassword
debconf-set-selections <<< "mysql-server mysql-server/root_password password $mysqlrootpassword"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $mysqlrootpassword"

echo "";

# Grab a password for Guacamole Database User Account
read -s -p "Enter the password that will be used for the Guacamole database: " guacdbuserpassword

# Install Features
apt-get -y install libcairo2-dev libpng12-dev libossp-uuid-dev libfreerdp-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev mysql-server mysql-client mysql-common mysql-utilities tomcat8 freerdp ghostscript wget curl
wget -O libjpeg-turbo-official_1.5.0_amd64.deb http://downloads.sourceforge.net/project/libjpeg-turbo/1.5.0/libjpeg-turbo-official_1.5.0_amd64.deb
dpkg -i libjpeg-turbo-official_1.5.0_amd64.deb

echo "Add GUACAMOLE_HOME to Tomcat8 ENV"
echo "" >> /etc/default/tomcat8
echo "# GUACAMOLE EVN VARIABLE" >> /etc/default/tomcat8
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat8

# Download Guacamole Files
wget -O guacamole-0.9.9.war http://downloads.sourceforge.net/project/guacamole/current/binary/guacamole-0.9.9.war
wget -O guacamole-server-0.9.9.tar.gz http://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-0.9.9.tar.gz
wget -O guacamole-auth-jdbc-0.9.9.tar.gz http://sourceforge.net/projects/guacamole/files/current/extensions/guacamole-auth-jdbc-0.9.9.tar.gz
wget -O mysql-connector-java-5.1.39.tar.gz http://dev.mysql.com/get/Downloads/Connector/j/mysql-connector-java-5.1.39.tar.gz

#Extract Guacamole Files
tar -xzf guacamole-server-0.9.9.tar.gz
tar -xzf guacamole-auth-jdbc-0.9.9.tar.gz
tar -xzf mysql-connector-java-5.1.39.tar.gz

# MAKE DIRECTORIES
mkdir /etc/guacamole
mkdir /etc/guacamole/lib
mkdir /etc/guacamole/extensions

# Install GUACD
cd guacamole-server-0.9.9
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig
systemctl enable guacd
cd ..

# Move files to correct locations
mv guacamole-0.9.9.war /etc/guacamole/guacamole.war
ln -s /etc/guacamole/guacamole.war /var/lib/tomcat8/webapps/
ln -s /usr/local/lib/freerdp/* /usr/lib/x86_64-linux-gnu/freerdp/.
cp mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /etc/guacamole/lib/
cp guacamole-auth-jdbc-0.9.9/mysql/guacamole-auth-jdbc-mysql-0.9.9.jar /etc/guacamole/extensions/

# Configure guacamole.properties
echo "mysql-hostname: localhost" >> /etc/guacamole/guacamole.properties
echo "mysql-port: 3306" >> /etc/guacamole/guacamole.properties
echo "mysql-database: guacamole_db" >> /etc/guacamole/guacamole.properties
echo "mysql-username: guacamole_user" >> /etc/guacamole/guacamole.properties
echo "mysql-password: $guacdbuserpassword" >> /etc/guacamole/guacamole.properties
rm -rf /usr/share/tomcat8/.guacamole
ln -s /etc/guacamole /usr/share/tomcat8/.guacamole

# restart tomcat
service tomcat8 restart

# Create guacamole_db and grant guacamole_user permissions to it
echo "create database guacamole_db; create user 'guacamole_user'@'localhost' identified by \"$guacdbuserpassword\";GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'localhost';flush privileges;" | mysql -u root -p$mysqlrootpassword

cat guacamole-auth-jdbc-0.9.9/mysql/schema/*.sql | mysql -u root -p$mysqlrootpassword guacamole_db

rm libjpeg-turbo-official_1.5.0_amd64.deb
rm guacamole-server-0.9.9.tar.gz
rm guacamole-auth-jdbc-0.9.9.tar.gz
rm mysql-connector-java-5.1.39.tar.gz

rm -rf mysql-connector-java-5.1.39/
rm -rf guacamole-auth-jdbc-0.9.9/
rm -rf guacamole-server-0.9.9/


echo "Your site should be available at http://127.0.0.1:8080/guacamole (or any other ip assigned to server);
echo "Set this up in your /etc/apache2/sites-enabled/000-default.conf - or whatever you use if you want a domain based system";
echo "<VirtualHost *:80>";
echo "   ServerName example.com";
echo "   ServerAlias www.example.com";
echo "   RewriteEngine on";
echo "   ProxyRequests off";
echo "   ProxyPreserveHost on";
echo "   RewriteCond %{HTTP_HOST} ^example.com(:80)?$";
echo "   RewriteRule /(.*) http://192.168.1.25:8080/guacamole/$1 [P]";
echo "</VirtualHost>";

echo -e "\n\n This would make your website available at http://example.com or  http://www.example.com";
echo -e "\nUsername / Password = 'guacadmin'";

echo -e "\n\n Configuration files for the web interface are located at /etc/guacamole/guacamole.properties"
echo -e "\n Configuration files for the server daemon can be specified by creating /etc/guacamole/guacd.conf"

echo -e "Tomcat configuration is at /etc/tomcat8/server.xml";
echo -e "You can set it up on a seperate port if needed with something like this:\n\n";
echo -e "<Service name="Guacamole">";
echo -e "<Connector port="8081" protocol="HTTP/1.1"";
echo -e "                   connectionTimeout="20000"";
echo -e "                   URIEncoding="UTF-8" />";
echo -e "       <Engine name="Catalina" defaultHost="localhost">";
echo -e "               <Realm className="org.apache.catalina.realm.LockOutRealm">";
echo -e "                       <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase" />";
echo -e "               </Realm>";
echo -e "               <Host name="localhost"  appBase="webapps" unpackWARs="true" autoDeploy="true">";
echo -e "               <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"";
echo -e "                          prefix="guacamole_access_log" suffix=".txt"";
echo -e "                          pattern="%h %l %u %t %v &quot;%r&quot; %s %b" />";
echo -e "               </Host>";
echo -e "       </Engine>";
echo -e "</Service>";

echo-e "\nHaving this second service in Tomcat may break it, if you can't log in, try removing it and go straight to the IPaddress:8080/guacamole to troubleshoot.
