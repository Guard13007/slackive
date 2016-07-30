#!/bin/bash

set -o errexit   # exit on error

# Prerequisites
echo "Please set up certificates before continuing."
echo "( wget https://dl.eff.org/certbot-auto"
echo "  chmod a+x certbot-auto )"
read -p " Press [Enter] to continue, or Ctrl+C to cancel."
sudo apt-get update
sudo apt-get install wget curl lua5.1 liblua5.1-0-dev unzip libreadline-dev libncurses5-dev libpcre3-dev openssl libssl-dev perl make build-essential mysql-server libmysql++-dev -y   # Make sure you note your MySQL password!
# OpenResty
cd ..
wget https://openresty.org/download/openresty-1.9.7.5.tar.gz   # Install a later version if available!
tar xvf openresty-1.9.7.5.tar.gz
cd openresty-1.9.7.5
./configure
make
sudo make install
cd ..
# LuaRocks
wget https://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz # Install a later version if available!
tar xvf luarocks-2.3.0.tar.gz
cd luarocks-2.3.0
./configure
make build
sudo make install
# some rocks
sudo luarocks install lapis
sudo luarocks install moonscript
sudo luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql
sudo luarocks install bcrypt
sudo luarocks install luacrypto
# cleanup
cd ..
rm -rf openresty*
rm -rf luarocks*
# okay now let's set it up
cd slackiver
git submodule init
git submodule update
openssl dhparam -out dhparams.pem 2048
cp secret.moon.example secret.moon
nano secret.moon   # Put the info needed in there!
moonc .
echo "Logging into MySQL (using root)..."
echo "Do 'CREATE DATABASE slackiver;' then 'exit' !"
echo "(& 'slackiver_dev' if you plan to use development environment)"
mysql -u root -p
lapis migrate production
# Slackiver as a service
echo "[Unit]
Description=Slackiver server

[Service]
Type=forking
WorkingDirectory=$(pwd)
ExecStart=$(which lapis) server production
ExecReload=$(which lapis) build production
ExecStop=$(which lapis) term

[Install]
WantedBy=multi-user.target" > slackiver.service
sudo cp ./slackiver.service /etc/systemd/system/slackiver.service
sudo systemctl daemon-reload
sudo systemctl enable slackiver.service
service slackiver start
echo "(Don't forget to proxy or pass to port 9443!)"
